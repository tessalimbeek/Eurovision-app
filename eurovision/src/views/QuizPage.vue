<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import quizzes from '../assets/quizzes.json'

const router = useRouter()
const route = useRoute()
const selectedQuiz = ref(null)
const currentQuestionIndex = ref(0)
const score = ref(0)

// reactive varaible, automatically updates
const currentQuestion = computed(() => {
  return selectedQuiz.value?.questions[currentQuestionIndex.value] ?? {}
})

function selectAnswer(index) {
  if (index === currentQuestion.value.correctIndex) {
    score.value++
  }

  const nextIndex = currentQuestionIndex.value + 1

  if (nextIndex >= selectedQuiz.value.questions.length) {
    finishQuiz()
  }

  currentQuestionIndex.value = nextIndex
}

function finishQuiz() {
  if (selectedQuiz.value) {
    localStorage.setItem(`quiz-score-${selectedQuiz.value.id}`, score.value.toString())
  }
}

function restartQuiz() {
  currentQuestionIndex.value = 0
  score.value = 0
}

function goBack() {
  router.back()
}

// when opening the page, find correct quiz from id in route
onMounted(() => {
  const quizId = route.params.quizId
  selectedQuiz.value = quizzes.find((q) => q.id === quizId)
})
</script>

<template>
  <main>
    <div @click="goBack" class="button-back">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="1.5"
        class="w-6 h-6"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
      </svg>
    </div>

    <div class="quiz-container">
      <h2>{{ selectedQuiz?.emoji }} {{ selectedQuiz?.title }}</h2>

      <div v-if="!selectedQuiz">
        <p>Quiz not found.</p>
      </div>

      <div v-else-if="currentQuestionIndex < selectedQuiz.questions.length">
        <p>{{ currentQuestionIndex + 1 }}. {{ currentQuestion.question }}</p>
        <ul>
          <li v-for="(answer, index) in currentQuestion.answers" :key="index">
            <button @click="selectAnswer(index)">
              {{ answer }}
            </button>
          </li>
        </ul>
      </div>

      <div v-else>
        <h3>🎉 Quiz Completed!</h3>
        <p>
          You got <strong>{{ score }}</strong> out of {{ selectedQuiz.questions.length }} correct.
        </p>
        <button @click="restartQuiz">Restart Quiz</button>
      </div>
    </div>
  </main>
</template>

<style scoped>
ul li {
  padding: 10px;
}
</style>
