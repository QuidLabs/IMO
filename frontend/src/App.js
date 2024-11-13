//import { useState } from 'react';
import { BrowserRouter as Router } from 'react-router-dom'

import { NotificationList } from './components/NotificationList'
import { Footer } from './components/Footer'
import { Header } from './components/Header'
import { DepositBar } from './components/DepositBar'

import { NotificationProvider } from './contexts/NotificationProvider'

import { useRoutes } from './Routes'
import { useAppContext } from "./contexts/AppContext"

import './App.scss'

function App() {
  const routes = useRoutes()
  const { addressMO } = useAppContext()
  //const [currentPage, setCurrentPage] = useState('home')
  
  return (
    <NotificationProvider>
      <NotificationList />
      <Router>
        <div className="app-root">
          <Header/>
          {/**<nav>
            <Link to="/" onClick={() => setCurrentPage('home')}>Bridge</Link>
            <Link to="/Mint" onClick={() => setCurrentPage('mint')}>Insure</Link>
          </nav>**/}
          <main className={`app-main`}>
            <div className="app-container">
              {routes}
            </div>
          </main>
          {addressMO ? <DepositBar address={addressMO} /> : null}
          <Footer />
        </div>
      </Router>
    </NotificationProvider>
  )
}

export default App
