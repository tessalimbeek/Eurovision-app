
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

    <div class="quiz-container p-4 bg-white rounded-2xl shadow max-w-xl mx-auto">
      <h2 class="text-xl font-bold mb-4 text-center">
        {{ selectedQuiz?.emoji }} {{ selectedQuiz?.title }}
      </h2>

      <div v-if="!selectedQuiz">
        <p class="text-center text-red-500">Quiz not found.</p>
      </div>

      <div v-else-if="currentQuestionIndex < selectedQuiz.questions.length">
        <p class="mb-2 font-semibold">
          {{ currentQuestionIndex + 1 }}. {{ currentQuestion.question }}
        </p>
        <ul class="space-y-2">
          <li v-for="(answer, index) in currentQuestion.answers" :key="index">
            <button
              class="w-full bg-gray-100 hover:bg-blue-100 rounded px-4 py-2 text-left"
              @click="selectAnswer(index)"
            >
              {{ answer }}
            </button>
          </li>
        </ul>
      </div>

      <div v-else class="text-center">
        <h3 class="text-lg font-semibold mb-2">🎉 Quiz Completed!</h3>
        <p>
          You got <strong>{{ score }}</strong> out of {{ selectedQuiz.questions.length }} correct.
        </p>
        <button
          @click="restartQuiz"
          class="mt-4 bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600"
        >
          Restart Quiz
        </button>
      </div>
    </div>
  </main>
</template>


<style scoped>
ul li {
  padding: 10px;
}
</style>
