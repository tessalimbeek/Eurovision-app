<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

// Set your countdown date/time
const targetDate = new Date('2026-05-10T21:00:00').getTime()

const timeLeft = ref({
  days: 0,
  hours: 0,
  minutes: 0,
  seconds: 0,
})

const isExpired = ref(false)
let interval = null

function updateCountdown() {
  const now = new Date().getTime()
  const distance = targetDate - now

  if (distance < 0) {
    isExpired.value = true
    clearInterval(interval)
    return
  }

  timeLeft.value = {
    days: Math.floor(distance / (1000 * 60 * 60 * 24)),
    hours: Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)),
    minutes: Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60)),
    seconds: Math.floor((distance % (1000 * 60)) / 1000),
  }
}

// on opening of the page, set interval and countdown
onMounted(() => {
  updateCountdown()
  interval = setInterval(updateCountdown, 1000)
})

// on leaving the page, clear interval
onUnmounted(() => {
  if (interval) {
    clearInterval(interval)
  }
})
</script>

<template>
  <main>
    <h1>Lavietjes Eurovision</h1>
    <div class="countdown-container">
      <h2 class="countdown-title">Event Countdown</h2>

      <div v-if="!isExpired" class="countdown-display">
        <div class="time-unit">
          <span class="time-number">{{ timeLeft.days }}</span>
          <span class="time-label">Days</span>
        </div>

        <div class="time-separator">:</div>

        <div class="time-unit">
          <span class="time-number">{{ String(timeLeft.hours).padStart(2, '0') }}</span>
          <span class="time-label">Hours</span>
        </div>

        <div class="time-separator">:</div>

        <div class="time-unit">
          <span class="time-number">{{ String(timeLeft.minutes).padStart(2, '0') }}</span>
          <span class="time-label">Minutes</span>
        </div>

        <div class="time-separator">:</div>

        <div class="time-unit">
          <span class="time-number">{{ String(timeLeft.seconds).padStart(2, '0') }}</span>
          <span class="time-label">Seconds</span>
        </div>
      </div>

      <div v-else class="expired-message">
        <h3>🎉 Event has started! 🎉</h3>
      </div>
    </div>

    <div class="quizz-button">
      <RouterLink to="/quiz">
        <button>Want to take a quiz?</button>
      </RouterLink>
    </div>
  </main>
</template>

<style scoped>
.quizz-button {
  display: flex;
  justify-content: center;
  padding: 30px 0;
}

.quizz-button a {
  width: 100%;
}

.quizz-button button {
  width: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
}

.countdown-container {
  text-align: center;
  padding: 2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 12px;
  color: white;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}

.countdown-title {
  font-size: 1.5rem;
  margin-bottom: 1.5rem;
  font-weight: bold;
}

.countdown-display {
  display: flex;
  justify-content: center;
  align-items: center;
  flex-wrap: wrap;
  gap: 1rem;
}

.time-unit {
  display: flex;
  flex-direction: column;
  align-items: center;
  background: rgba(255, 255, 255, 0.1);
  padding: 1rem;
  border-radius: 8px;
  backdrop-filter: blur(10px);
  min-width: 80px;
}

.time-number {
  font-size: 2rem;
  font-weight: bold;
  line-height: 1;
}

.time-label {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 1px;
  margin-top: 0.5rem;
  opacity: 0.8;
}

.time-separator {
  font-size: 2rem;
  font-weight: bold;
  opacity: 0.6;
}

.expired-message {
  font-size: 1.5rem;
  padding: 2rem;
}

@media (max-width: 768px) {
  .countdown-display {
    flex-direction: column;
  }

  .time-separator {
    display: none;
  }

  .time-unit {
    min-width: 120px;
  }
}
</style>
