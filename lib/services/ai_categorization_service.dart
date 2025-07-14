import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sage_wallet_reborn/data/repositories/category_repository.dart';
import 'package:sage_wallet_reborn/models/category.dart' as fin_category;
import 'package:sage_wallet_reborn/services/api_client.dart';
import 'package:sage_wallet_reborn/core/di/injector.dart';

class AICategorizationService {
  final CategoryRepository _categoryRepository;
  final ApiClient _apiClient = getIt<ApiClient>();

  Map<String, String> _brandCategoryMap = {};
  Map<String, List<String>> _generalKeywordCategoryMap = {};
  bool _isInitialized = false;

  AICategorizationService(this._categoryRepository) {
    _loadDictionaries();
  }

  Future<void> _loadDictionaries() async {
    if (_isInitialized) return;

    _brandCategoryMap = _baseBrandMap;
    _generalKeywordCategoryMap = _baseGeneralMap;

    try {
      const supabaseUrl = 'https://xdofjorgomwdyawmwbcj.supabase.co';
      const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhkb2Zqb3Jnb213ZHlhd213YmNqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkzMzE0MTcsImV4cCI6MjA2NDkwNzQxN30.2i9ru8fXLZEYD_jNHoHd0ZJmN4k9gKcPOChdiuL_AMY';
      final url = Uri.parse('$supabaseUrl/storage/v1/object/public/ai-dictionaries/global_lexicon.json');
      
      final response = await http.get(url, headers: {
        'apikey': supabaseAnonKey,
        'Authorization': 'Bearer $supabaseAnonKey'
      });

      if (response.statusCode == 200) {
        final globalDict = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        globalDict.forEach((key, value) {
          _brandCategoryMap[key] = value.toString();
        });
      }
    } catch (e) {
      //
    }
    _isInitialized = true;
  }

  String? _extractKeywordFromDescription(String description) {
    final lowerCaseDescription = description.toLowerCase();
    
    for(String brand in _brandCategoryMap.keys) {
        if(lowerCaseDescription.contains(brand)) return brand;
    }

    final words = lowerCaseDescription.split(RegExp(r'[\s,.]+'));
    for (var entry in _generalKeywordCategoryMap.entries) {
      for (var keyword in entry.value) {
        if(words.contains(keyword)) return keyword;
      }
    }
    
    return null;
  }

  Future<void> rememberUserChoice(String description, fin_category.Category category) async {
    final keyword = _extractKeywordFromDescription(description);
    if (keyword == null || category.id == null || description.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ai_override_$keyword', category.id!);
    
    try {
      await _apiClient.post('/ai/log', body: {
        'keyword': keyword,
        'category_name': category.name,
      });
    } catch (e) {
      //
    }
  }

  Future<fin_category.Category?> suggestCategory({required String description, required int walletId}) async {
    if (!_isInitialized) await _loadDictionaries();
    if (description.trim().isEmpty) return null;

    final lowerCaseDescription = description.toLowerCase();
    final categoriesEither = await _categoryRepository.getAllCategories(walletId);

    return categoriesEither.fold(
      (failure) => null,
      (allCategories) {
         final categoriesByName = { for (var cat in allCategories) cat.name.toLowerCase(): cat };
        final categoriesById = { for (var cat in allCategories) if(cat.id != null) cat.id!: cat };
        
        final keyword = _extractKeywordFromDescription(lowerCaseDescription);
        if (keyword != null) {
          final prefsFuture = SharedPreferences.getInstance().then((prefs) {
            final overrideCategoryId = prefs.getInt('ai_override_$keyword');
            if (overrideCategoryId != null && categoriesById.containsKey(overrideCategoryId)) {
              return categoriesById[overrideCategoryId];
            }
            return null;
          });
          return prefsFuture;
        }
        
        for (var entry in _brandCategoryMap.entries) {
          final brand = entry.key;
          final categoryName = entry.value;
          if (lowerCaseDescription.contains(brand)) {
            if (categoriesByName.containsKey(categoryName.toLowerCase())) {
              return categoriesByName[categoryName.toLowerCase()];
            }
            final type = (categoryName == 'Зарплата' || categoryName == 'Подарунки та Допомога' || categoryName == 'Додатковий Дохід' || categoryName == 'Інвестиції') ? fin_category.CategoryType.income : fin_category.CategoryType.expense;
            return fin_category.Category(name: categoryName, type: type);
          }
        }

        for (var entry in _generalKeywordCategoryMap.entries) {
          final categoryName = entry.key;
          final keywords = entry.value;
          for (var keyword in keywords) {
            if (lowerCaseDescription.contains(keyword)) {
              if (categoriesByName.containsKey(categoryName.toLowerCase())) {
                return categoriesByName[categoryName.toLowerCase()];
              }
              final type = (categoryName == 'Зарплата' || categoryName == 'Подарунки та Допомога' || categoryName == 'Додатковий Дохід' || categoryName == 'Інвестиції') ? fin_category.CategoryType.income : fin_category.CategoryType.expense;
              return fin_category.Category(name: categoryName, type: type);
            }
          }
        }
        
        return null;
      }
    );
  }

  static const Map<String, String> _baseBrandMap = {
    'сільпо': 'Продукти', 'атб': 'Продукти', 'varus': 'Продукти', 'novus': 'Продукти',
    'ашан': 'Продукти', 'metro': 'Продукти', 'фора': 'Продукти', 'еко-маркет': 'Продукти', 'наш край': 'Продукти', 'thrash': 'Продукти',
    'rozetka': 'Покупки', 'comfy': 'Електроніка', 'foxtrot': 'Електроніка',
    'allo': 'Електроніка', 'цитрус': 'Електроніка', 'moyo': 'Електроніка', 'apple': 'Електроніка', 'samsung': 'Електроніка', 
    'xiaomi': 'Електроніка', 'eldorado': 'Електроніка', 'telemart': 'Електроніка',
    'аптека': 'Здоров\'я та медицина', 'подорожник': 'Здоров\'я та медицина', 'синево': 'Здоров\'я та медицина', 'dobrobut': 'Здоров\'я та медицина', 'synevo': 'Здоров\'я та медицина', 'діла': 'Здоров\'я та медицина',
    'wog': 'Автомобіль', 'okko': 'Автомобіль', 'shell': 'Автомобіль',
    'soccar': 'Автомобіль', 'klo': 'Автомобіль', 'upg': 'Автомобіль', 'брсм': 'Автомобіль',
    'bolt': 'Таксі', 'uklon': 'Таксі', 'uber': 'Таксі',
     'glovo': 'Доставка їжі', 'bolt food': 'Доставка їжі', 'loko': 'Доставка їжі', 'zakaz.ua': 'Продукти', 'нова пошта': 'Послуги', 'укрпошта': 'Послуги',
    'zara': 'Одяг та взуття', 'h&m': 'Одяг та взуття', 'bershka': 'Одяг та взуття',
    'intertop': 'Одяг та взуття', 'answear': 'Одяг та взуття', 'md fashion': 'Одяг та взуття', 'lc waikiki': 'Одяг та взуття', 'reserved': 'Одяг та взуття', 'pull&bear': 'Одяг та взуття', 'stradivarius': 'Одяг та взуття',
     'mcdonald\'s': 'Кафе, Бари, Ресторани', 'макдональдз': 'Кафе, Бари, Ресторани', 'kfc': 'Кафе, Бари, Ресторани',
    'пузата хата': 'Кафе, Бари, Ресторани', 'salateira': 'Кафе, Бари, Ресторани', 'lviv croissants': 'Кафе, Бари, Ресторани',
    'арома кава': 'Кафе, Бари, Ресторани', 'мафія': 'Кафе, Бари, Ресторани', 'сушія': 'Кафе, Бари, Ресторани', 'домінос': 'Кафе, Бари, Ресторани',
    'starbucks': 'Кафе, Бари, Ресторани',
    'eva': 'Побут', 'watsons': 'Побут', 'prostor': 'Побут', 'jysk': 'Дім та Побут', 'епіцентр': 'Дім та Побут', 'леруа мерлен': 'Дім та Побут',
    'lanet': 'Інтернет та ТБ', 'воля': 'Інтернет та ТБ', 'тріолан': 'Інтернет та ТБ', 'київстар': 'Зв\'язок', 'vodafone': 'Зв\'язок', 'lifecell': 'Зв\'язок',
    'netflix': 'Підписки', 'spotify': 'Підписки', 'youtube premium': 'Підписки',
     'google one': 'Підписки', 'icloud': 'Підписки', 'megogo': 'Підписки', 'sweet.tv': 'Підписки',
    'google drive': 'Підписки', 'dropbox': 'Підписки', 'patreon': 'Підписки',
    'projector': 'Освіта', 'hillel': 'Освіта', 'goit': 'Освіта', 'prometheus': 'Освіта',
    'multiplex': 'Розваги та Хобі', 'planeta kino': 'Розваги та Хобі', 'playstation': 'Розваги та Хобі', 'steam': 'Розваги та Хобі',
    'укрзалізниця': 'Транспорт', 'уз': 'Транспорт', 'busfor': 'Транспорт', 'infobus': 'Транспорт', 'blablacar': 'Транспорт', 'ryanair': 'Подорожі', 'wizzair': 'Подорожі', 'мау': 'Подорожі',
  };

  static const Map<String, List<String>> _baseGeneralMap = {
    'Продукти': ['ринок', 'супермаркет', 'гастроном', 'продуктовий', 'базар', 'їжа', 'вода', 'хліб', 'молоко', 'мясо', 'риба', 'овочі', 'фрукти', 'бакалія', 'крупи', 'солодощі'],
    'Кафе, Бари, Ресторани': ['ресторан', 'кафе', 'їдальня', 'їжа на виніс', 'кав\'ярня', 'обід', 'вечеря', 'сніданок', 'ланч', 'coffee', 'latte', 'cappuccino', 'еспресо', 'донер', 'шаурма', 'кебаб', 'хот-дог', 'піца', 'pizza', 'бургер', 'бар', 'паб', 'пиво', 'коктейль', 'вино', 'алкоголь', 'закуски', 'пивас'],
    'Транспорт': ['метро', 'автобус', 'тролейбус', 'трамвай', 'маршрутка', 'електричка', 'проїзний', 'автостанція', 'вокзал', 'жетон', 'прокат самокатів', 'оренда авто'],
    'Житло та Комунальні Послуги': ['оренда квартири', 'квартплата', 'комуналка', 'комунальні', 'електроенергія', 'світло', 'газ', 'вода', 'опалення', 'осбб', 'інтернет', 'кабельне', 'вивіз сміття', 'домогосподарка', 'прибирання'],
    'Одяг та взуття': ['штани', 'сукня', 'кросівки', 'футболка', 'куртка', 'светр', 'черевики', 'костюм', 'білизна', 'одяг', 'взуття'],
    'Здоров\'я та медицина': ['ліки', 'вітаміни', 'бад', 'лікар', 'клініка', 'аналізи', 'стоматолог', 'дантист', 'окуліст', 'масаж', 'психолог'],
    'Особистий Догляд та Косметика': ['косметика', 'парфуми', 'шампунь', 'гель', 'крем', 'перукарня', 'стрижка', 'барбершоп', 'манікюр', 'педикюр', 'салон краси', 'косметолог'],
    'Розваги та Хобі': ['кіно', 'кінотеатр', 'квитки в кіно', 'театр', 'опера', 'балет', 'концерт', 'книги', 'ігри', 'боулінг', 'квест', 'хобі', 'музей', 'виставка', 'риболовля', 'пряжа', 'настільні ігри'],
    'Освіта': ['курси', 'тренінг', 'семінар', 'вебінар', 'лекція', 'університет', 'навчання', 'репетитор', 'іноземні мови', 'англійська'],
    'Техніка та Електроніка': ['телефон', 'ноутбук', 'навушники', 'гаджет', 'комп\'ютер', 'планшет', 'техніка', 'зарядка'],
    'Дім та Побут': ['меблі', 'посуд', 'побутова хімія', 'ремонт', 'декор', 'господарські товари', 'будматеріали', 'сантехніка', 'інструменти', 'шпалери'],
    'Подарунки та Квіти': ['подарунок', 'квіти', 'сувенір', 'день народження'],
    'Подорожі': ['літак', 'авіаквитки', 'готель', 'хостел', 'booking.com', 'airbnb', 'оренда житла', 'турагенція', 'віза', 'страхування'],
    'Автомобіль': ['бензин', 'дизель', 'газ', 'азс', 'сто', 'мийка', 'шиномонтаж', 'запчастини', 'масло', 'ремонт авто', 'паркінг', 'штраф'],
    'Податки та Фінанси': ['податки', 'комісія банку', 'переказ коштів', 'кредит', 'відсотки', 'обмін валют', 'єсв', 'фоп', 'єдиний податок'],
    'Зарплата': ['аванс', 'премія', 'бонус', 'відпускні', 'винагорода', 'зп'],
    'Додатковий Дохід': ['фриланс', 'проект', 'гонорар', 'халтура', 'підробіток', 'продаж', 'кешбек', 'cashback'],
    'Подарунки та Допомога': ['повернули борг', 'допомога', 'батьки'],
    'Інвестиції': ['дивіденди', 'відсотки по депозиту', 'продаж акцій', 'криптовалюта', 'bitcoin', 'ethereum'],
    'Послуги': ['юридичні послуги', 'нотаріус', 'пошта'],
    'Тварини': ['корм для', 'зоомагазин', 'ветеринар', 'грумінг', 'іграшки для'],
  };
}