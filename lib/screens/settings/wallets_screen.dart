import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/wallet_provider.dart';
import '../../providers/app_mode_provider.dart';
import '../../models/wallet.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../core/di/injector.dart';
import '../../services/auth_service.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final InvitationRepository _invitationRepo = getIt<InvitationRepository>(instanceName: 'supabase');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (mounted) {
      await context.read<WalletProvider>().loadWallets();
    }
  }

  Future<void> _changeUserRole(int walletId, String memberUserId, String newRole) async {
    await context.read<WalletProvider>().changeUserRole(walletId, memberUserId, newRole);
  }

  Future<void> _removeUser(BuildContext context, int walletId, String memberUserId) async {
    final messenger = ScaffoldMessenger.of(context);
    await context.read<WalletProvider>().removeUserFromWallet(walletId, memberUserId);
    if (mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Користувача видалено з гаманця.')));
    }
  }

  Future<void> _generateAndShareInvite(BuildContext context, Wallet wallet) async {
    if (wallet.id == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final invitationToken = await _invitationRepo.generateInvitation(wallet.id!);
      final link = 'https://cortexfinapp.com/invite?token=$invitationToken';
      await Share.share('Привіт! Запрошую тебе до свого спільного гаманця "${wallet.name}" в додатку Гаманець Мудреця:\n\n$link');
    } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text('Помилка створення запрошення: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();
    final wallets = walletProvider.wallets;
    final authService = context.watch<AuthService>();
    final currentUserId = authService.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управління гаманцями'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          )
        ],
      ),
      body: walletProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  final isCurrent = wallet.id == walletProvider.currentWallet?.id;
                  final amIOwner = wallet.ownerUserId == currentUserId;
                  return Card(
                    elevation: isCurrent ? 4 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: ExpansionTile(
                      leading: Icon(
                        isCurrent
                            ? Icons.account_balance_wallet
                            : Icons.account_balance_wallet_outlined,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 32,
                      ),
                      title: Text(wallet.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text('Учасників: ${wallet.members.length}'),
                      trailing: amIOwner
                          ? Consumer<AppModeProvider>(
                              builder: (context, appModeProvider, child) {
                                return IconButton(
                                  icon: const Icon(Icons.share_outlined),
                                  tooltip: 'Запросити за посиланням',
                                  onPressed: appModeProvider.isOnline
                                      ? () => _generateAndShareInvite(
                                          context, wallet)
                                      : null,
                                );
                              },
                            )
                          : null,
                      onExpansionChanged: (isExpanding) {
                        if (isExpanding && wallet.id != null &&
                            wallet.id != walletProvider.currentWallet?.id) {
                          context
                              .read<WalletProvider>()
                              .switchWallet(wallet.id!);
                        }
                      },
                      children: [
                        const Divider(height: 1),
                        ...wallet.members.map((member) {
                          bool isMemberOwner = member.user.id == wallet.ownerUserId;
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.person, size: 20),
                            title: Text(member.user.name),
                            trailing: amIOwner && !isMemberOwner && wallet.id != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DropdownButton<String>(
                                        value: member.role,
                                        underline: const SizedBox(),
                                        items: const [
                                          DropdownMenuItem(
                                              value: 'editor',
                                              child: Text('Редактор')),
                                          DropdownMenuItem(
                                              value: 'viewer',
                                              child: Text('Глядач')),
                                        ],
                                        onChanged: (newRole) {
                                          if (newRole != null) {
                                            _changeUserRole(wallet.id!,
                                                member.user.id, newRole);
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                            Icons.person_remove_outlined,
                                            color: Theme.of(context).colorScheme.error),
                                        onPressed: () => _removeUser(context,
                                            wallet.id!, member.user.id),
                                      ),
                                    ],
                                  )
                                : Text(
                                    member.role == 'owner'
                                        ? 'Власник'
                                        : (member.role == 'editor'
                                            ? 'Редактор'
                                            : 'Глядач'),
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontStyle: FontStyle.italic),
                                  ),
                          );
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _showContextMenu(
                                    context, wallet, wallets.length > 1),
                                child: const Text('Опції гаманця'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditWalletDialog(context),
        label: const Text('Новий гаманець'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Wallet wallet, bool canDelete) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Редагувати назву'),
              onTap: () {
                Navigator.pop(ctx);
                _showAddEditWalletDialog(context, walletToEdit: wallet);
              },
            ),
            if (canDelete && wallet.id != null)
              ListTile(
                leading: Icon(Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error),
                title: Text('Видалити гаманець',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteWallet(context, wallet);
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddEditWalletDialog(BuildContext context,
      {Wallet? walletToEdit}) async {
    final walletProvider = context.read<WalletProvider>();
    final isEditing = walletToEdit != null;
    final nameController = TextEditingController(text: walletToEdit?.name ?? '');

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Редагувати гаманець' : 'Новий гаманець'),
          content: TextField(
            controller: nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Назва гаманця"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Скасувати'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('Зберегти'),
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  if (isEditing) {
                    final updatedWallet = Wallet(
                      id: walletToEdit.id,
                      name: name,
                      isDefault: walletToEdit.isDefault,
                      ownerUserId: walletToEdit.ownerUserId,
                    );
                    await walletProvider.updateWallet(updatedWallet);
                  } else {
                    await walletProvider.createWallet(name: name);
                  }
                  if (navigator.context.mounted) {
                    navigator.pop();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteWallet(
      BuildContext context, Wallet wallet) async {
    if (wallet.id == null) return;
    final walletProvider = context.read<WalletProvider>();
    final messenger = ScaffoldMessenger.of(context);
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Видалити гаманець?'),
          content: Text(
              'Гаманець "${wallet.name}" буде видалено разом з усіма пов\'язаними даними. Цю дію неможливо скасувати.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Скасувати'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Видалити'),
              onPressed: () async {
                final dialogNavigator = Navigator.of(dialogContext);
                final result = await walletProvider.deleteWallet(wallet.id!);
                result.fold(
                  (failure) {
                       if (mounted) {
                         messenger.showSnackBar(SnackBar(content: Text(failure.userMessage)));
                      }
                  },
                  (_) {}
                );
                if (dialogNavigator.context.mounted) {
                  dialogNavigator.pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
}