import React from 'react'
import { Routes, Route } from 'react-router-dom'
import MaintPage from './pages/MainPage/MaintPage'

export const useRoutes = () => (
    <Routes>
      <Route path="/" element={<MaintPage />} />
    </Routes>
  )