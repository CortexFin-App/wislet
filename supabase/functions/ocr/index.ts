import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { corsHeaders } from '../_shared/cors.ts'

const GOOGLE_VISION_API_KEY = Deno.env.get('GOOGLE_VISION_API_KEY')
const GOOGLE_API_URL = `https://vision.googleapis.com/v1/images:annotate?key=${GOOGLE_VISION_API_KEY}`

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (!GOOGLE_VISION_API_KEY) {
    return new Response(JSON.stringify({ error: 'Google Vision API key is not configured.' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 500,
    })
  }

  try {
    const { image } = await req.json()
    if (!image) {
      throw new Error('Image data is required.')
    }

    const requestBody = {
      requests: [
        {
          image: {
            content: image,
          },
          features: [
            {
              type: 'TEXT_DETECTION',
            },
          ],
        },
      ],
    }

    const visionResponse = await fetch(GOOGLE_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(requestBody),
    })

    if (!visionResponse.ok) {
      const errorBody = await visionResponse.json()
      throw new Error(`Google Vision API request failed: ${JSON.stringify(errorBody)}`)
    }

    const visionData = await visionResponse.json()
    const fullTextAnnotation = visionData.responses[0]?.fullTextAnnotation?.text || ''

    return new Response(JSON.stringify({ text: fullTextAnnotation }), {
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