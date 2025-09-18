import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:wislet/core/di/injector.dart';
import 'package:wislet/data/repositories/category_repository.dart';
import 'package:wislet/models/category.dart' as fin_category;
import 'package:wislet/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    if (_isInitialized) {
      return;
    }

    _brandCategoryMap = _baseBrandMap;
    _generalKeywordCategoryMap = _baseGeneralMap;

    try {
      const supabaseUrl = 'https://xdofjorgomwdyawmwbcj.supabase.co';
      const supabaseAnonKey =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhkb2Zqb3Jnb213ZHlhd213YmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMzE0MTcsImV4cCI6MjA2NDkwNzQxN30.2i9ru8fXLZEYD_jNHoHd0ZJmN4k9gKcPOChdiuL_AMY';
      final url = Uri.parse(
        '$supabaseUrl/storage/v1/object/public/ai-dictionaries/global_lexicon.json',
      );

      final response = await http.get(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
        },
      );

      if (response.statusCode == 200) {
        final globalDict =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        globalDict.forEach((key, value) {
          _brandCategoryMap[key] = value.toString();
        });
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
    String description,
    fin_category.Category category,
  ) async {
    final keyword = _extractKeywordFromDescription(description);
    if (keyword == null || category.id == null || description.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_override_$keyword', category.id!);

    try {
      await _apiClient.post(
        '/ai/log',
        body: {
          'keyword': keyword,
          'category_name': category.name,
        },
      );
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
    if (description.trim().isEmpty) {
      return null;
    }

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
            'Р—Р°СЂРїР»Р°С‚Р°',
            'РџРѕРґР°СЂСѓРЅРєРё С‚Р° Р”РѕРїРѕРјРѕРіР°',
            'Р”РѕРґР°С‚РєРѕРІРёР№ Р”РѕС…С–Рґ',
            'Р†РЅРІРµСЃС‚РёС†С–С—',
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
              'Р—Р°СЂРїР»Р°С‚Р°',
              'РџРѕРґР°СЂСѓРЅРєРё С‚Р° Р”РѕРїРѕРјРѕРіР°',
              'Р”РѕРґР°С‚РєРѕРІРёР№ Р”РѕС…С–Рґ',
              'Р†РЅРІРµСЃС‚РёС†С–С—',
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
    'СЃС–Р»СЊРїРѕ': 'РџСЂРѕРґСѓРєС‚Рё',
    'Р°С‚Р±': 'РџСЂРѕРґСѓРєС‚Рё',
    'varus': 'РџСЂРѕРґСѓРєС‚Рё',
    'novus': 'РџСЂРѕРґСѓРєС‚Рё',
    'Р°С€Р°РЅ': 'РџСЂРѕРґСѓРєС‚Рё',
    'metro': 'РџСЂРѕРґСѓРєС‚Рё',
    'С„РѕСЂР°': 'РџСЂРѕРґСѓРєС‚Рё',
    'РµРєРѕ-РјР°СЂРєРµС‚': 'РџСЂРѕРґСѓРєС‚Рё',
    'РЅР°С€ РєСЂР°Р№': 'РџСЂРѕРґСѓРєС‚Рё',
    'thrash': 'РџСЂРѕРґСѓРєС‚Рё',
    'rozetka': 'РџРѕРєСѓРїРєРё',
    'comfy': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'foxtrot': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'allo': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'С†РёС‚СЂСѓСЃ': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'moyo': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'apple': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'samsung': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'xiaomi': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'eldorado': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'telemart': 'Р•Р»РµРєС‚СЂРѕРЅС–РєР°',
    'Р°РїС‚РµРєР°': "Р—РґРѕСЂРѕРІ'СЏ С‚Р° РјРµРґРёС†РёРЅР°",
    'РїРѕРґРѕСЂРѕР¶РЅРёРє': "Р—РґРѕСЂРѕРІ'СЏ С‚Р° РјРµРґРёС†РёРЅР°",
    'СЃС–РЅРµРІРѕ': "Р—РґРѕСЂРѕРІ'СЏ С‚Р° РјРµРґРёС†РёРЅР°",
    'dobrobut': "Р—РґРѕСЂРѕРІ'СЏ С‚Р° РјРµРґРёС†РёРЅР°",
    'synevo': "Р—РґРѕСЂРѕРІ'СЏ С‚Р° РјРµРґРёС†РёРЅР°",
    'РґС–Р»Р°': "Р—РґРѕСЂРѕРІ'СЏ С‚Р° РјРµРґРёС†РёРЅР°",
    'wog': 'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'okko': 'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'shell': 'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'soccar': 'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'klo': 'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'upg': 'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'Р±СЂСЃРј': 'РђРІС‚РѕРјРѕР±С–Р»СЊ',
    'bolt': 'РўР°РєСЃС–',
    'uklon': 'РўР°РєСЃС–',
    'uber': 'РўР°РєСЃС–',
    'glovo': 'Р”РѕСЃС‚Р°РІРєР° С—Р¶С–',
    'bolt food': 'Р”РѕСЃС‚Р°РІРєР° С—Р¶С–',
    'loko': 'Р”РѕСЃС‚Р°РІРєР° С—Р¶С–',
    'zakaz.ua': 'РџСЂРѕРґСѓРєС‚Рё',
    'РЅРѕРІР° РїРѕС€С‚Р°': 'РџРѕСЃР»СѓРіРё',
    'СѓРєСЂРїРѕС€С‚Р°': 'РџРѕСЃР»СѓРіРё',
    'zara': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'h&m': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'bershka': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'intertop': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'answear': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'md fashion': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'lc waikiki': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'reserved': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'pull&bear': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    'stradivarius': 'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ',
    "mcdonald's": 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'РјР°РєРґРѕРЅР°Р»СЊРґР·': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'kfc': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'РїСѓР·Р°С‚Р° С…Р°С‚Р°': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'salateira': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'lviv croissants': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'Р°СЂРѕРјР° РєР°РІР°': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'РјР°С„С–СЏ': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'СЃСѓС€С–СЏ': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'РґРѕРјС–РЅРѕСЃ': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'starbucks': 'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё',
    'eva': 'РџРѕР±СѓС‚',
    'watsons': 'РџРѕР±СѓС‚',
    'prostor': 'РџРѕР±СѓС‚',
    'jysk': 'Р”С–Рј С‚Р° РџРѕР±СѓС‚',
    'РµРїС–С†РµРЅС‚СЂ': 'Р”С–Рј С‚Р° РџРѕР±СѓС‚',
    'Р»РµСЂСѓР° РјРµСЂР»РµРЅ': 'Р”С–Рј С‚Р° РџРѕР±СѓС‚',
    'lanet': 'Р†РЅС‚РµСЂРЅРµС‚ С‚Р° РўР‘',
    'РІРѕР»СЏ': 'Р†РЅС‚РµСЂРЅРµС‚ С‚Р° РўР‘',
    'С‚СЂС–РѕР»Р°РЅ': 'Р†РЅС‚РµСЂРЅРµС‚ С‚Р° РўР‘',
    'РєРёС—РІСЃС‚Р°СЂ': "Р—РІ'СЏР·РѕРє",
    'vodafone': "Р—РІ'СЏР·РѕРє",
    'lifecell': "Р—РІ'СЏР·РѕРє",
    'netflix': 'РџС–РґРїРёСЃРєРё',
    'spotify': 'РџС–РґРїРёСЃРєРё',
    'youtube premium': 'РџС–РґРїРёСЃРєРё',
    'google one': 'РџС–РґРїРёСЃРєРё',
    'icloud': 'РџС–РґРїРёСЃРєРё',
    'megogo': 'РџС–РґРїРёСЃРєРё',
    'sweet.tv': 'РџС–РґРїРёСЃРєРё',
    'google drive': 'РџС–РґРїРёСЃРєРё',
    'dropbox': 'РџС–РґРїРёСЃРєРё',
    'patreon': 'РџС–РґРїРёСЃРєРё',
    'projector': 'РћСЃРІС–С‚Р°',
    'hillel': 'РћСЃРІС–С‚Р°',
    'goit': 'РћСЃРІС–С‚Р°',
    'prometheus': 'РћСЃРІС–С‚Р°',
    'multiplex': 'Р РѕР·РІР°РіРё С‚Р° РҐРѕР±С–',
    'planeta kino': 'Р РѕР·РІР°РіРё С‚Р° РҐРѕР±С–',
    'playstation': 'Р РѕР·РІР°РіРё С‚Р° РҐРѕР±С–',
    'steam': 'Р РѕР·РІР°РіРё С‚Р° РҐРѕР±С–',
    'СѓРєСЂР·Р°Р»С–Р·РЅРёС†СЏ': 'РўСЂР°РЅСЃРїРѕСЂС‚',
    'СѓР·': 'РўСЂР°РЅСЃРїРѕСЂС‚',
    'busfor': 'РўСЂР°РЅСЃРїРѕСЂС‚',
    'infobus': 'РўСЂР°РЅСЃРїРѕСЂС‚',
    'blablacar': 'РўСЂР°РЅСЃРїРѕСЂС‚',
    'ryanair': 'РџРѕРґРѕСЂРѕР¶С–',
    'wizzair': 'РџРѕРґРѕСЂРѕР¶С–',
    'РјР°Сѓ': 'РџРѕРґРѕСЂРѕР¶С–',
  };

  static const Map<String, List<String>> _baseGeneralMap = {
    'РџСЂРѕРґСѓРєС‚Рё': [
      'СЂРёРЅРѕРє',
      'СЃСѓРїРµСЂРјР°СЂРєРµС‚',
      'РіР°СЃС‚СЂРѕРЅРѕРј',
      'РїСЂРѕРґСѓРєС‚РѕРІРёР№',
      'Р±Р°Р·Р°СЂ',
      'С—Р¶Р°',
      'РІРѕРґР°',
      'С…Р»С–Р±',
      'РјРѕР»РѕРєРѕ',
      'РјСЏСЃРѕ',
      'СЂРёР±Р°',
      'РѕРІРѕС‡С–',
      'С„СЂСѓРєС‚Рё',
      'Р±Р°РєР°Р»С–СЏ',
      'РєСЂСѓРїРё',
      'СЃРѕР»РѕРґРѕС‰С–',
    ],
    'РљР°С„Рµ, Р‘Р°СЂРё, Р РµСЃС‚РѕСЂР°РЅРё': [
      'СЂРµСЃС‚РѕСЂР°РЅ',
      'РєР°С„Рµ',
      'С—РґР°Р»СЊРЅСЏ',
      'С—Р¶Р° РЅР° РІРёРЅС–СЃ',
      "РєР°РІ'СЏСЂРЅСЏ",
      'РѕР±С–Рґ',
      'РІРµС‡РµСЂСЏ',
      'СЃРЅС–РґР°РЅРѕРє',
      'Р»Р°РЅС‡',
      'coffee',
      'latte',
      'cappuccino',
      'РµСЃРїСЂРµСЃРѕ',
      'РґРѕРЅРµСЂ',
      'С€Р°СѓСЂРјР°',
      'РєРµР±Р°Р±',
      'С…РѕС‚-РґРѕРі',
      'РїС–С†Р°',
      'pizza',
      'Р±СѓСЂРіРµСЂ',
      'Р±Р°СЂ',
      'РїР°Р±',
      'РїРёРІРѕ',
      'РєРѕРєС‚РµР№Р»СЊ',
      'РІРёРЅРѕ',
      'Р°Р»РєРѕРіРѕР»СЊ',
      'Р·Р°РєСѓСЃРєРё',
      'РїРёРІР°СЃ',
    ],
    'РўСЂР°РЅСЃРїРѕСЂС‚': [
      'РјРµС‚СЂРѕ',
      'Р°РІС‚РѕР±СѓСЃ',
      'С‚СЂРѕР»РµР№Р±СѓСЃ',
      'С‚СЂР°РјРІР°Р№',
      'РјР°СЂС€СЂСѓС‚РєР°',
      'РµР»РµРєС‚СЂРёС‡РєР°',
      'РїСЂРѕС—Р·РЅРёР№',
      'Р°РІС‚РѕСЃС‚Р°РЅС†С–СЏ',
      'РІРѕРєР·Р°Р»',
      'Р¶РµС‚РѕРЅ',
      'РїСЂРѕРєР°С‚ СЃР°РјРѕРєР°С‚С–РІ',
      'РѕСЂРµРЅРґР° Р°РІС‚Рѕ',
    ],
    'Р–РёС‚Р»Рѕ С‚Р° РљРѕРјСѓРЅР°Р»СЊРЅС– РџРѕСЃР»СѓРіРё': [
      'РѕСЂРµРЅРґР° РєРІР°СЂС‚РёСЂРё',
      'РєРІР°СЂС‚РїР»Р°С‚Р°',
      'РєРѕРјСѓРЅР°Р»РєР°',
      'РєРѕРјСѓРЅР°Р»СЊРЅС–',
      'РµР»РµРєС‚СЂРѕРµРЅРµСЂРіС–СЏ',
      'СЃРІС–С‚Р»Рѕ',
      'РіР°Р·',
      'РІРѕРґР°',
      'РѕРїР°Р»РµРЅРЅСЏ',
      'РѕСЃР±Р±',
      'С–РЅС‚РµСЂРЅРµС‚',
      'РєР°Р±РµР»СЊРЅРµ',
      'РІРёРІС–Р· СЃРјС–С‚С‚СЏ',
      'РґРѕРјРѕРіРѕСЃРїРѕРґР°СЂРєР°',
      'РїСЂРёР±РёСЂР°РЅРЅСЏ',
    ],
    'РћРґСЏРі С‚Р° РІР·СѓС‚С‚СЏ': [
      'С€С‚Р°РЅРё',
      'СЃСѓРєРЅСЏ',
      'РєСЂРѕСЃС–РІРєРё',
      'С„СѓС‚Р±РѕР»РєР°',
      'РєСѓСЂС‚РєР°',
      'СЃРІРµС‚СЂ',
      'С‡РµСЂРµРІРёРєРё',
      'РєРѕСЃС‚СЋРј',
      'Р±С–Р»РёР·РЅР°',
      'РѕРґСЏРі',
      'РІР·СѓС‚С‚СЏ',
    ],
    "Р—РґРѕСЂРѕРІ'СЏ С‚Р° РјРµРґРёС†РёРЅР°": [
      'Р»С–РєРё',
      'РІС–С‚Р°РјС–РЅРё',
      'Р±Р°Рґ',
      'Р»С–РєР°СЂ',
      'РєР»С–РЅС–РєР°',
      'Р°РЅР°Р»С–Р·Рё',
      'СЃС‚РѕРјР°С‚РѕР»РѕРі',
      'РґР°РЅС‚РёСЃС‚',
      'РѕРєСѓР»С–СЃС‚',
      'РјР°СЃР°Р¶',
      'РїСЃРёС…РѕР»РѕРі',
    ],
    'РћСЃРѕР±РёСЃС‚РёР№ Р”РѕРіР»СЏРґ С‚Р° РљРѕСЃРјРµС‚РёРєР°': [
      'РєРѕСЃРјРµС‚РёРєР°',
      'РїР°СЂС„СѓРјРё',
      'С€Р°РјРїСѓРЅСЊ',
      'РіРµР»СЊ',
      'РєСЂРµРј',
      'РїРµСЂСѓРєР°СЂРЅСЏ',
      'СЃС‚СЂРёР¶РєР°',
      'Р±Р°СЂР±РµСЂС€РѕРї',
      'РјР°РЅС–РєСЋСЂ',
      'РїРµРґРёРєСЋСЂ',
      'СЃР°Р»РѕРЅ РєСЂР°СЃРё',
      'РєРѕСЃРјРµС‚РѕР»РѕРі',
    ],
    'Р РѕР·РІР°РіРё С‚Р° РҐРѕР±С–': [
      'РєС–РЅРѕ',
      'РєС–РЅРѕС‚РµР°С‚СЂ',
      'РєРІРёС‚РєРё РІ РєС–РЅРѕ',
      'С‚РµР°С‚СЂ',
      'РѕРїРµСЂР°',
      'Р±Р°Р»РµС‚',
      'РєРѕРЅС†РµСЂС‚',
      'РєРЅРёРіРё',
      'С–РіСЂРё',
      'Р±РѕСѓР»С–РЅРі',
      'РєРІРµСЃС‚',
      'С…РѕР±С–',
      'РјСѓР·РµР№',
      'РІРёСЃС‚Р°РІРєР°',
      'СЂРёР±РѕР»РѕРІР»СЏ',
      'РїСЂСЏР¶Р°',
      'РЅР°СЃС‚С–Р»СЊРЅС– С–РіСЂРё',
    ],
    'РћСЃРІС–С‚Р°': [
      'РєСѓСЂСЃРё',
      'С‚СЂРµРЅС–РЅРі',
      'СЃРµРјС–РЅР°СЂ',
      'РІРµР±С–РЅР°СЂ',
      'Р»РµРєС†С–СЏ',
      'СѓРЅС–РІРµСЂСЃРёС‚РµС‚',
      'РЅР°РІС‡Р°РЅРЅСЏ',
      'СЂРµРїРµС‚РёС‚РѕСЂ',
      'С–РЅРѕР·РµРјРЅС– РјРѕРІРё',
      'Р°РЅРіР»С–Р№СЃСЊРєР°',
    ],
    'РўРµС…РЅС–РєР° С‚Р° Р•Р»РµРєС‚СЂРѕРЅС–РєР°': [
      'С‚РµР»РµС„РѕРЅ',
      'РЅРѕСѓС‚Р±СѓРє',
      'РЅР°РІСѓС€РЅРёРєРё',
      'РіР°РґР¶РµС‚',
      "РєРѕРјРї'СЋС‚РµСЂ",
      'РїР»Р°РЅС€РµС‚',
      'С‚РµС…РЅС–РєР°',
      'Р·Р°СЂСЏРґРєР°',
    ],
    'Р”С–Рј С‚Р° РџРѕР±СѓС‚': [
      'РјРµР±Р»С–',
      'РїРѕСЃСѓРґ',
      'РїРѕР±СѓС‚РѕРІР° С…С–РјС–СЏ',
      'СЂРµРјРѕРЅС‚',
      'РґРµРєРѕСЂ',
      'РіРѕСЃРїРѕРґР°СЂСЃСЊРєС– С‚РѕРІР°СЂРё',
      'Р±СѓРґРјР°С‚РµСЂС–Р°Р»Рё',
      'СЃР°РЅС‚РµС…РЅС–РєР°',
      'С–РЅСЃС‚СЂСѓРјРµРЅС‚Рё',
      'С€РїР°Р»РµСЂРё',
    ],
    'РџРѕРґР°СЂСѓРЅРєРё С‚Р° РљРІС–С‚Рё': [
      'РїРѕРґР°СЂСѓРЅРѕРє',
      'РєРІС–С‚Рё',
      'СЃСѓРІРµРЅС–СЂ',
      'РґРµРЅСЊ РЅР°СЂРѕРґР¶РµРЅРЅСЏ',
    ],
    'РџРѕРґРѕСЂРѕР¶С–': [
      'Р»С–С‚Р°Рє',
      'Р°РІС–Р°РєРІРёС‚РєРё',
      'РіРѕС‚РµР»СЊ',
      'С…РѕСЃС‚РµР»',
      'booking.com',
      'airbnb',
      'РѕСЂРµРЅРґР° Р¶РёС‚Р»Р°',
      'С‚СѓСЂР°РіРµРЅС†С–СЏ',
      'РІС–Р·Р°',
      'СЃС‚СЂР°С…СѓРІР°РЅРЅСЏ',
    ],
    'РђРІС‚РѕРјРѕР±С–Р»СЊ': [
      'Р±РµРЅР·РёРЅ',
      'РґРёР·РµР»СЊ',
      'РіР°Р·',
      'Р°Р·СЃ',
      'СЃС‚Рѕ',
      'РјРёР№РєР°',
      'С€РёРЅРѕРјРѕРЅС‚Р°Р¶',
      'Р·Р°РїС‡Р°СЃС‚РёРЅРё',
      'РјР°СЃР»Рѕ',
      'СЂРµРјРѕРЅС‚ Р°РІС‚Рѕ',
      'РїР°СЂРєС–РЅРі',
      'С€С‚СЂР°С„',
    ],
    'РџРѕРґР°С‚РєРё С‚Р° Р¤С–РЅР°РЅСЃРё': [
      'РїРѕРґР°С‚РєРё',
      'РєРѕРјС–СЃС–СЏ Р±Р°РЅРєСѓ',
      'РїРµСЂРµРєР°Р· РєРѕС€С‚С–РІ',
      'РєСЂРµРґРёС‚',
      'РІС–РґСЃРѕС‚РєРё',
      'РѕР±РјС–РЅ РІР°Р»СЋС‚',
      'С”СЃРІ',
      'С„РѕРї',
      'С”РґРёРЅРёР№ РїРѕРґР°С‚РѕРє',
    ],
    'Р—Р°СЂРїР»Р°С‚Р°': [
      'Р°РІР°РЅСЃ',
      'РїСЂРµРјС–СЏ',
      'Р±РѕРЅСѓСЃ',
      'РІС–РґРїСѓСЃРєРЅС–',
      'РІРёРЅР°РіРѕСЂРѕРґР°',
      'Р·Рї',
    ],
    'Р”РѕРґР°С‚РєРѕРІРёР№ Р”РѕС…С–Рґ': [
      'С„СЂРёР»Р°РЅСЃ',
      'РїСЂРѕС”РєС‚',
      'РіРѕРЅРѕСЂР°СЂ',
      'С…Р°Р»С‚СѓСЂР°',
      'РїС–РґСЂРѕР±С–С‚РѕРє',
      'РїСЂРѕРґР°Р¶',
      'РєРµС€Р±РµРє',
      'cashback',
    ],
    'РџРѕРґР°СЂСѓРЅРєРё С‚Р° Р”РѕРїРѕРјРѕРіР°': [
      'РїРѕРІРµСЂРЅСѓР»Рё Р±РѕСЂРі',
      'РґРѕРїРѕРјРѕРіР°',
      'Р±Р°С‚СЊРєРё',
    ],
    'Р†РЅРІРµСЃС‚РёС†С–С—': [
      'РґРёРІС–РґРµРЅРґРё',
      'РІС–РґСЃРѕС‚РєРё РїРѕ РґРµРїРѕР·РёС‚Сѓ',
      'РїСЂРѕРґР°Р¶ Р°РєС†С–Р№',
      'РєСЂРёРїС‚РѕРІР°Р»СЋС‚Р°',
      'bitcoin',
      'ethereum',
    ],
    'РџРѕСЃР»СѓРіРё': [
      'СЋСЂРёРґРёС‡РЅС– РїРѕСЃР»СѓРіРё',
      'РЅРѕС‚Р°СЂС–СѓСЃ',
      'РїРѕС€С‚Р°',
    ],
    'РўРІР°СЂРёРЅРё': [
      'РєРѕСЂРј РґР»СЏ',
      'Р·РѕРѕРјР°РіР°Р·РёРЅ',
      'РІРµС‚РµСЂРёРЅР°СЂ',
      'РіСЂСѓРјС–РЅРі',
      'С–РіСЂР°С€РєРё РґР»СЏ',
    ],
  };
}
