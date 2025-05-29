import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

import LoginView from '../views/LoginView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
    path: '/',
    component: LoginView,
    },
    {
    path: '/home',
    component: HomeView,
    },
    {
      path: '/chat',
      name: 'chat',
      component: () => import('../views/ChatView.vue'),
    },
    {
    path: '/scores',
    name: 'scores',
    component: () => import('../views/ScoresListView.vue'),
    },
    {
    path: '/profile',
    name: 'profile',
    component: () => import('../views/ProfileView.vue'),
    },
    {
    path: '/vote/:countryId',
    name: 'VotingPage',
    component: () => import('@/views/VotingPage.vue')
    },        
  ],
})


export default router
