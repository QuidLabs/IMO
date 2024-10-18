import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import MetamaskProvider from "./contexts/MetamaskProvider"
import { AppContextProvider } from "./contexts/AppContext"

const letsgo = ReactDOM.createRoot(document.getElementById('letsgo'))
// Read the API key from the environment variables
const infuraAPIKey = process.env.INFURA_API_KEY;

letsgo.render(
  <React.StrictMode>
    <MetamaskProvider
      sdkOptions={{
        dappMetadata: {
          name: "QU!D",
          //url: window.location.href,
        },
        infuraAPIKey: infuraAPIKey
      }}>
      <AppContextProvider>
        <App />
      </AppContextProvider>
    </MetamaskProvider>
  </React.StrictMode>
)

