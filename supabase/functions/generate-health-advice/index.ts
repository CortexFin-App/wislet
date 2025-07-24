import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

interface FinancialProfile {
  score: number
  savingsRate: number
  isSavingsRatePositive: boolean
  debtToIncomeRatio: number
  budgetAdherence: number
  activeGoals: number
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const profile: FinancialProfile = await req.json()
    let title = ''
    let positive = ''
    let suggestion = ''

    if (profile.score >= 80) {
      title = `Твій Score: ${profile.score}. Відмінно! 🚀`
      positive = `Ти ефективно керуєш фінансами. Твій коефіцієнт заощаджень складає ${(profile.savingsRate * 100).toFixed(0)}%.`
      suggestion = profile.activeGoals > 0 
        ? 'Спробуй збільшити суму поповнення для однієї з твоїх цілей, щоб досягти її ще швидше.'
        : 'Час поставити нову амбітну фінансову ціль, щоб продовжити зростання.'
    } else if (profile.score >= 50) {
      title = `Твій Score: ${profile.score}. Добре, але є куди рости.`
      if (profile.isSavingsRatePositive) {
        positive = `Ти вже на правильному шляху, заощаджуючи ${(profile.savingsRate * 100).toFixed(0)}% від доходу.`
      } else {
        positive = 'Ти добре контролюєш свої витрати, але поки не заощаджуєш.'
      }

      if (profile.budgetAdherence < 0.8) {
        suggestion = 'Схоже, ти іноді виходиш за рамки бюджету. Спробуй переглянути ліміти по категоріям, щоб зробити їх більш реалістичними.'
      } else if (profile.debtToIncomeRatio > 0.4) {
        suggestion = 'Твоє боргове навантаження є значним. Спробуй направити частину вільних коштів на дострокове погашення боргів.'
      } else {
        suggestion = 'Проаналізуй свої підписки. Можливо, серед них є ті, якими ти більше не користуєшся?'
      }
    } else {
      title = `Твій Score: ${profile.score}. Потрібен план дій.`
      positive = 'Головне — почати. Перший крок до фінансової свободи вже зроблено.'
      if (!profile.isSavingsRatePositive) {
        suggestion = 'Твої витрати перевищують доходи. Спробуй знайти 1-2 категорії, де можна скоротити витрати, щоб вийти в плюс.'
      } else {
        suggestion = 'Спробуй створити бюджет за методом "конвертів", щоб чітко бачити, куди йдуть твої гроші.'
      }
    }
    
    return new Response(JSON.stringify({ title, positive, suggestion }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})