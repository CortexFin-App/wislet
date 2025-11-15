import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/models/category.dart' as fin_category;
import 'package:wislet/services/api_client.dart';

class AICategorizationService {
  AICategorizationService(this._categoryRepository) {
    _loadDictionaries();
  }

  final CategoryRepository _categoryRepository;
  final ApiClient _apiClient = getIt<ApiClient>();

  Map<String, String> _brandCategoryMap = {};
  Map<String, List<String>> _generalKeywordCategoryMap = {};
  bool _isInitialized = false;

  Future<void> _loadDictionaries() async {
    if (_isInitialized) return;

    _brandCategoryMap = _baseBrandMap;
    _generalKeywordCategoryMap = _baseGeneralMap;

    try {
      const supabaseUrl = 'https://xdofjorgomwdyawmwbcj.supabase.co';
      const supabaseAnonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhkb2Zqb3Jnb213ZHlhd213YmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMzE0MTcsImV4cCI6MjA2NDkwNzQxN30.2i9ru8fXLZEYD_jNHoHd0ZJmN4k9gKcPOChdiuL_AMY';
      final url = Uri.parse(
          '$supabaseUrl/storage/v1/object/public/ai-dictionaries/global_lexicon.json',);

      final response = await http.get(url, headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey',
      },);

      if (response.statusCode == 200) {
        final globalDict =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        _brandCategoryMap.addEntries(globalDict.entries.map(
          (e) => MapEntry(e.key, e.value.toString()),
        ),);
      }
    } on Exception {
      // Ignore
    }
    _isInitialized = true;
  }

  String? _extractKeywordFromDescription(String description) {
    final lowerCaseDescription = description.toLowerCase();

    for (final brand in _brandCategoryMap.keys) {
      if (lowerCaseDescription.contains(brand)) return brand;
    }

    final words = lowerCaseDescription.split(RegExp(r'[\s,.]+'));
    for (final entry in _generalKeywordCategoryMap.entries) {
      for (final keyword in entry.value) {
        if (words.contains(keyword)) return keyword;
      }
    }

    return null;
  }

  Future<void> rememberUserChoice(
      String description, fin_category.Category category,) async {
    final keyword = _extractKeywordFromDescription(description);
    if (keyword == null || category.id == null || description.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_override_$keyword', category.id!);

    try {
      await _apiClient.post('/ai/log', body: {
        'keyword': keyword,
        'category_name': category.name,
      },);
    } on Exception {
      // Ignore
    }
  }

  Future<fin_category.Category?> suggestCategory({
    required String description,
    required int walletId,
  }) async {
    if (!_isInitialized) {
      await _loadDictionaries();
    }
    if (description.trim().isEmpty) return null;

    final lowerCaseDescription = description.toLowerCase();
    final categoriesEither =
        await _categoryRepository.getAllCategories(walletId);

    return categoriesEither.fold((failure) async => null,
        (allCategories) async {
      final categoriesByName = {
        for (final cat in allCategories) cat.name.toLowerCase(): cat,
      };
      final categoriesById = {
        for (final cat in allCategories)
          if (cat.id != null) cat.id!: cat,
      };

      final keyword = _extractKeywordFromDescription(lowerCaseDescription);
      if (keyword != null) {
        final prefs = await SharedPreferences.getInstance();
        final overrideCategoryId = prefs.getInt('ai_override_$keyword');
        if (overrideCategoryId != null &&
            categoriesById.containsKey(overrideCategoryId)) {
          return categoriesById[overrideCategoryId];
        }
      }

      for (final entry in _brandCategoryMap.entries) {
        final brand = entry.key;
        final categoryName = entry.value;
        if (lowerCaseDescription.contains(brand)) {
          if (categoriesByName.containsKey(categoryName.toLowerCase())) {
            return categoriesByName[categoryName.toLowerCase()];
          }
          const incomeCategories = [
            'Зарплата',
            'Подарунки та Допомога',
            'Додатковий Дохід',
            'Інвестиції',
          ];
          final type = incomeCategories.contains(categoryName)
              ? fin_category.CategoryType.income
              : fin_category.CategoryType.expense;
          return fin_category.Category(name: categoryName, type: type);
        }
      }

      for (final entry in _generalKeywordCategoryMap.entries) {
        final categoryName = entry.key;
        final keywords = entry.value;
        for (final keyword in keywords) {
          if (lowerCaseDescription.contains(keyword)) {
            if (categoriesByName.containsKey(categoryName.toLowerCase())) {
              return categoriesByName[categoryName.toLowerCase()];
            }
            const incomeCategories = [
              'Зарплата',
              'Подарунки та Допомога',
              'Додатковий Дохід',
              'Інвестиції',
            ];
            final type = incomeCategories.contains(categoryName)
                ? fin_category.CategoryType.income
                : fin_category.CategoryType.expense;
            return fin_category.Category(name: categoryName, type: type);
          }
        }
      }

      return null;
    });
  }

  static const Map<String, String> _baseBrandMap = {
    'сільпо': 'Продукти',
    'атб': 'Продукти',
    'varus': 'Продукти',
    'novus': 'Продукти',
    'ашан': 'Продукти',
    'metro': 'Продукти',
    'фора': 'Продукти',
    'еко-маркет': 'Продукти',
    'наш край': 'Продукти',
    'thrash': 'Продукти',
    'rozetka': 'Покупки',
    'comfy': 'Електроніка',
    'foxtrot': 'Електроніка',
    'allo': 'Електроніка',
    'цитрус': 'Електроніка',
    'moyo': 'Електроніка',
    'apple': 'Електроніка',
    'samsung': 'Електроніка',
    'xiaomi': 'Електроніка',
    'eldorado': 'Електроніка',
    'telemart': 'Електроніка',
    'аптека': "Здоров'я та медицина",
    'пodorожник': "Здоров'я та медицина",
    'сінево': "Здоров'я та медицина",
    'dobrobut': "Здоров'я та медицина",
    'synevo': "Здоров'я та медицина",
    'діла': "Здоров'я та медицина",
    'wog': 'Автомобіль',
    'okko': 'Автомобіль',
    'shell': 'Автомобіль',
    'soccar': 'Автомобіль',
    'klo': 'Автомобіль',
    'upg': 'Автомобіль',
    'брсм': 'Автомобіль',
    'bolt': 'Таксі',
    'uklon': 'Таксі',
    'uber': 'Таксі',
    'glovo': 'Доставка їжі',
    'bolt food': 'Доставка їжі',
    'loko': 'Доставка їжі',
    'nova poshta': 'Послуги',
    'укрпошта': 'Послуги',
    'zara': 'Одяг та взуття',
    'h&m': 'Одяг та взуття',
    'bershka': 'Одяг та взуття',
    'intertop': 'Одяг та взуття',
    'answear': 'Одяг та взуття',
    'lc waikiki': 'Одяг та взуття',
    'reserved': 'Одяг та взуття',
    'pull&bear': 'Одяг та взуття',
    'stradivarius': 'Одяг та взуття',
    "mcdonald's": 'Кафе, Бари, Ресторани',
    'kfc': 'Кафе, Бари, Ресторани',
    'пузата хата': 'Кафе, Бари, Ресторани',
    'salateira': 'Кафе, Бари, Ресторани',
    'lviv croissants': 'Кафе, Бари, Ресторани',
    'арома кава': 'Кафе, Бари, Ресторани',
    'мафія': 'Кафе, Бари, Ресторани',
    'сушия': 'Кафе, Бари, Ресторани',
    'домінос': 'Кафе, Бари, Ресторани',
    'eva': 'Побут',
    'watsons': 'Побут',
    'prostor': 'Побут',
    'jysk': 'Дім та Побут',
    'епіцентр': 'Дім та Побут',
    'леруа мерлен': 'Дім та Побут',
    'lanet': 'Інтернет та ТБ',
    'воля': 'Інтернет та ТБ',
    'тріолан': 'Інтернет та ТБ',
    'київстар': "Зв'язок",
    'vodafone': "Зв'язок",
    'lifecell': "Зв'язок",
    'netflix': 'Підписки',
    'spotify': 'Підписки',
    'youtube premium': 'Підписки',
    'google one': 'Підписки',
    'icloud': 'Підписки',
    'megogo': 'Підписки',
    'sweet.tv': 'Підписки',
    'patreon': 'Підписки',
    'projector': 'Освіта',
    'hillel': 'Освіта',
    'goit': 'Освіта',
    'prometheus': 'Освіта',
    'multiplex': 'Розваги та Хобі',
    'planeta kino': 'Розваги та Хобі',
    'playstation': 'Розваги та Хобі',
    'steam': 'Розваги та Хобі',
    'укрзалізниця': 'Транспорт',
    'uz': 'Транспорт',
    'busfor': 'Транспорт',
    'infobus': 'Транспорт',
    'blablacar': 'Транспорт',
    'ryanair': 'Подорожі',
    'wizzair': 'Подорожі',
    'мау': 'Подорожі',
  };

  static const Map<String, List<String>> _baseGeneralMap = {
    'Продукти': ['ринок', 'супермаркет', 'їжа', 'молоко', 'м’ясо', 'фрукти'],
    'Кафе, Бари, Ресторани': ['кафе', 'ресторани', 'піца', 'бургер', 'вино'],
    'Транспорт': ['метро', 'автобус', 'маршрутка', 'вокзал', 'таксі'],
    'Житло та Комунальні Послуги': [
      'оренда',
      'квартира',
      'світло',
      'газ',
      'вода',
      'комуналка',
    ],
    'Одяг та Взуття': ['одяг', 'взуття', 'куртка', 'штани', 'сукня'],
    'Здоровʼя та Медицина': ['ліки', 'вітаміни', 'клініка', 'лікар', 'аналізи'],
    'Освіта': ['курси', 'університет', 'лекція', 'навчання'],
    'Дім та Побут': ['меблі', 'ремонт', 'декор', 'посуд'],
    'Подорожі': ['літак', 'готель', 'страхування', 'тур'],
    'Автомобіль': ['бензин', 'СТО', 'ремонт авто', 'шини', 'паркінг'],
    'Подарунки та Квіти': ['подарунок', 'квіти', 'сувенір'],
    'Інвестиції': ['акції', 'криптовалюта', 'bitcoin', 'депозит'],
  };
}
