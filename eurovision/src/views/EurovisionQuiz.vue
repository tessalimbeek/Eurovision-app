<script setup>
import { useRouter } from 'vue-router'
import { ref, onMounted } from 'vue'
import quizzesData from '@/assets/quizzes.json'

const router = useRouter()
const quizzes = ref([])

// when opening page, load quizzed
onMounted(() => {
  quizzes.value = quizzesData.map((q) => ({ ...q, score: null }))

  // Load saved scores
  quizzes.value.forEach((quiz) => {
    const savedScore = localStorage.getItem(`quiz-score-${quiz.id}`)
    if (savedScore !== null) {
      quiz.score = parseInt(savedScore)
    }
  })
})

function startQuiz(id) {
  router.push(`/quiz/${id}`)
}

function goBack() {
  router.back()
}
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

    <h2>Choose a Eurovision Quiz</h2>

    <div class="quiz-list">
      <div class="quiz-item" v-for="quiz in quizzes" :key="quiz.id">
        <button class="quiz-button" @click="startQuiz(quiz.id)">
          <span>{{ quiz.emoji }} {{ quiz.title }}</span>
          <div class="score-part" v-if="quiz.score !== null">
            <span>Score:</span>
            <div class="score">
              {{ quiz.score }}
            </div>
          </div>
        </button>
      </div>
    </div>
  </main>
</template>

<style scoped>
.quiz-list {
  display: flex;
  gap: 20px;
  flex-direction: column;
}

.quiz-item button {
  width: 100%;
}

.quiz-button {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
}

.score-part {
  display: flex;
  flex-direction: row;
  gap: 10px;
}

.score {
  background: white;
  color: black;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 0.75rem;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  z-index: 1;
}
</style>
