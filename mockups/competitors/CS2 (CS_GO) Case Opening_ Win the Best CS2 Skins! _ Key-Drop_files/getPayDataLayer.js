const REQUEST_DELAY = 5000
const COOKIE_BANNER_LS_KEY = 'cookies-banner-v2'
// Wait up to 60s for the user to interact with the cookie banner so that the
// Purchase event is fired AFTER consent is granted. Without this, the event is
// often fired with consent in 'revoke'/LDU state which breaks Advanced
// Matching and attribution to the originating ad click.
const CONSENT_WAIT_MAX_MS = 60000
const CONSENT_POLL_INTERVAL_MS = 250

const hasConsentDecision = () => {
  try {
    const value = localStorage.getItem(COOKIE_BANNER_LS_KEY)
    return value === 'accepted' || value === 'rejected' || value === 'true'
  } catch (e) {
    return true // If localStorage is unavailable, do not block the event.
  }
}

const waitForConsentDecision = () => {
  if (hasConsentDecision()) return Promise.resolve()

  return new Promise((resolve) => {
    const startedAt = Date.now()
    const intervalId = window.setInterval(() => {
      if (hasConsentDecision() || Date.now() - startedAt >= CONSENT_WAIT_MAX_MS) {
        window.clearInterval(intervalId)
        resolve()
      }
    }, CONSENT_POLL_INTERVAL_MS)
  })
}

const getPay = () => {
  const handleResponse = async (res) => {
    try {
      return await res.json()
    } catch (err) {
      return new Error("Couldn't parse the response, it's not a JSON.")
    }
  }

  return fetch(SITE_URL + 'apiData/Payment/dataLayer')
    .then(handleResponse)
    .then(async (data) => {
      if (!data?.data?.length) return

      // Hold the Purchase event until the user makes a consent decision so
      // Meta receives it with the correct consent state and Advanced Matching
      // signal. Backend marks the row as processed (check=1) on read, so we
      // only get a single chance to fire this event.
      await waitForConsentDecision()

      data.data.forEach((el) => {
        const parameters = {
          transaction_id: el.id,
          value: el.amount,
          currency: 'USD',
        }

        if (el.promoCode) {
          parameters.coupon = el.promoCode
        }

        /*
            Track with Google Analytics.
            'purchase' is OUR custom event, but shouldn't be changed without disscussing it with Business first.
          */
        window.gtag?.('event', 'purchase', parameters)

        /*
            Track with Meta Pixel.
            'Purchase' is a standard event of Meta Pixel, DO NOT change that name.
          */
        window.fbq?.('track', 'Purchase', parameters)
      })
    })
    .catch(console.error)
}

window.setTimeout(() => {
  navigator.locks.request(
    'reportPaymentData',
    {
      ifAvailable: true,
    },
    (lock) => lock && getPay(),
  )
}, REQUEST_DELAY)
