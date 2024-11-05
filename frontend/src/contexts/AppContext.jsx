import { createContext, useState, useContext, useCallback, useRef} from "react"
import { useSDK } from "@metamask/sdk-react"
import { formatUnits, parseUnits } from "@ethersproject/units"
import { BigNumber } from "@ethersproject/bignumber"
import { Web3Provider } from "@ethersproject/providers"

import Web3 from "web3"

import { QUID, SDAI,  MO, SUSDE, addressQD, addressSDAI, addressSUSDE, addressMO } from "../utils/constant"

const contextState = {
  connectToMetaMask: () => { },
  getSdai: () => { },
  getSales: () => { },
  getTotalInfo: () => { },
  getUserInfo: () => { },
  getDepositInfo: () => { },
  getTotalSupply: () => { },
  setNotifications: () => { },
  setStorage: () => { },
  resetAccounts: () => { },
  choiseButton: () => {},
  setSwipe: () => { },
  swipeStatus: false,
  chooseButton: null,
  account: "",
  connected: false,
  connecting: false,
  provider: {},
  sdk: {},
  web3: {}
}

const AppContext = createContext(contextState)

export const AppContextProvider = ({ children }) => {
  const [account, setAccount] = useState("")
  const { sdk, connected, connecting, provider } = useSDK()

  const [quid, setQuid] = useState(null)
  const [sdai, setSdai] = useState(null)

  const [QDbalance, setQdBalance] = useState(null)
  const [SDAIbalance, setSdaiBalance] = useState(null)

  const [mo, setMO] = useState(null)
  const [susde, setSusde] = useState(null)

  const [currentTimestamp, setAccountTimestamp] = useState(0)

  const [notifications, setNotifications] = useState('')

  const [swipeStatus, setSwipeStatus] = useState(false)

  const SECONDS_IN_DAY = 86400

  const setStorage = useCallback((newNotifications) => {
    try {
      setNotifications(newNotifications)

      localStorage.setItem("consoleNotifications", JSON.stringify(newNotifications))
    } catch (error) {
      console.error("Error setting notifications:", error)
    }
  }, [])

  const getTotalSupply = useCallback(async () => {
    try {
      if (account && connected && quid) {
        const timestamp = Math.floor(Date.now() / 1000)

        setAccountTimestamp(Number(timestamp.toString()))

        const [totalSupplyCap] = await Promise.all([
          quid.methods.get_total_supply_cap().call(),
          quid.methods.totalSupply().call()
        ])

        const totalCapInt = totalSupplyCap ? parseInt(formatUnits(totalSupplyCap, 18)) : null

        if (totalCapInt) return totalCapInt
      }
    } catch (error) {
      console.error("Some problem with getSupply: ", error)
      return null
    }
  }, [setAccountTimestamp, account, connected, quid])

  const getSales = useCallback(async () => {
    try {
      if (account && quid && sdai && addressQD && mo && addressMO) {
        const days = await quid.methods.DAYS().call()
        const startDate = await quid.methods.START().call()

        const salesInfo = {
          mintPeriodDays: String(Number(days) / SECONDS_IN_DAY),
          smartContractStartTimestamp: startDate.toString()
        }

        return salesInfo
      }
      return null
    } catch (error) {
      console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
    }
  }, [account, sdai, quid, mo])

  const getTotalInfo = useCallback(async () => {
    try {
      if (connected && account && quid && sdai && addressQD) {
        const totalSupply = await quid.methods.totalSupply().call()
        const formattedTotalMinted = formatUnits(totalSupply, 18).split(".")[0]

        const total = await quid.methods.get_total_deposits().call()
        const formattedTotalDeposited = formatUnits(total.toString(), 18)

        const totalInfo = {
          total_dep: formattedTotalDeposited,
          total_mint: formattedTotalMinted
        }

        return totalInfo
      }
    } catch (error) {
      console.error("Error in updateInfo: ", error)
    }
  }, [account, connected, quid, sdai, susde])

  const getUserInfo = useCallback(async () => {
    try {
      if (connected && account && quid) {
        const timestamp = Math.floor(Date.now() / 1000)

        setAccountTimestamp(Number(timestamp.toString()))

        const qdAmount = parseUnits("1", 18).toBigInt()

        const data = await quid.methods.qd_amt_to_dollar_amt(qdAmount, currentTimestamp).call()

        const value = Number(formatUnits(data, 18) * 100)

        const price = BigNumber.from(Math.floor(value).toString())

        const info = await mo.methods.get_info(account).call()

        const actualUsd = Number(info[0]) / 1e18
        const actualQD = Number(info[1]) / 1e18

        const userInfo = {
          actualUsd: actualUsd,
          actualQD: actualQD,
          price: price,
          info: info
        }

        return userInfo
      }
    } catch (error) {
      console.warn(`Failed to get account info:`, error)
    }
  }, [account, connected, currentTimestamp, quid, mo])

  const getDepositInfo = useCallback(async () => {
    try {
      if (connected && account && mo) {
        const more_info = await mo.methods.get_more_info(account).call()

        // TODO use formatUnits !!!
        const workEthBalance = (parseFloat(more_info[0]) / 1e18)
        const workUsdBalance = (parseFloat(more_info[1]) / 1e18)
        const wethEthBalance = (parseFloat(more_info[2]) / 1e18)
        const wethUsdBalance = (parseFloat(more_info[3]) / 1e18)

        const depoInfo = {
          work_eth_balance: workEthBalance,
          work_usd_balance: workUsdBalance,
          weth_eth_balance: wethEthBalance,
          weth_usd_balance: wethUsdBalance,
        }
        return depoInfo
      }
    } catch (error) {
      console.warn(`Failed to get account info:`, error)
    }
  }, [account, connected, mo])

  const getSdai = useCallback(async () => {
    try {
      if (account && sdai) await sdai.methods.mint(account).send({ from: account })
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, sdai])

  const getWalletBalance = useCallback(async () => {
    try {
      if (sdai && account) {
        const balance = await sdai.methods.balanceOf(account).call()
        const formatSdaiBalance = (parseFloat(balance) / 1e18).toFixed(2)

        setSdaiBalance(formatSdaiBalance)

        const ethersProvider = new Web3Provider(provider)
        const mainBalance = await ethersProvider.getBalance(account)
        const formatEthBalance = (parseFloat(mainBalance) / 1e18).toFixed(4)

        return {sdai: formatSdaiBalance, eth: formatEthBalance}
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [setSdaiBalance, account, provider, sdai])

  const getQdBalance = useCallback(async () => {
    try {
      if (quid && account) {
        const balance = await quid.methods.balanceOf(account).call()

        setQdBalance(parseFloat(balance) / 1e18)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [setQdBalance, account, quid])

  const resetAccounts = useCallback(async (reset = false) => {
    try {
      if (reset) setAccount("")
    } catch (error) {
      console.warn(`Failed to set all info:`, error)
    }
  }, [])

  const connectToMetaMask = useCallback(async () => {
    try {
      if (!account) {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })

        setAccount(accounts[0])

        if (accounts && provider) {

          const web3Instance = new Web3(provider)
          const quidContract = new web3Instance.eth.Contract(QUID, addressQD)
          const moContract = new web3Instance.eth.Contract(MO, addressMO)
          const usdeContract = new web3Instance.eth.Contract(SDAI, addressSDAI)
          const susdeContract = new web3Instance.eth.Contract(SUSDE, addressSUSDE)

          setMO(moContract)
          setQuid(quidContract)
          setSdai(usdeContract)
          setSusde(susdeContract)
        }
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [setAccount, setMO, setSdai, setSusde, setQuid, account, provider])

  const chooseButton = useRef(null)

  const choiseButton = useCallback((name) => {
      try{
          const newButton = name

          return chooseButton.current = newButton
      }catch(error){
          console.error("Error with button's choising: ", error)
      }
  },[chooseButton])

  const setSwipe = useCallback(()=>{
    try{
      if(swipeStatus) setSwipeStatus(false)
      else setSwipeStatus(true)
    }catch(error){
      console.error("Error with swipe: ", error)
    }
  },[swipeStatus])

  return (
    <AppContext.Provider
      value={{
        connectToMetaMask,
        getSdai,
        getTotalInfo,
        getUserInfo,
        getDepositInfo,
        getSales,
        getTotalSupply,
        resetAccounts,
        getWalletBalance,
        getQdBalance,
        setNotifications,
        setStorage,
        setMO,
        account,
        addressMO,
        connected,
        connecting,
        currentTimestamp,
        provider,
        sdk,
        quid,
        sdai,
        QDbalance,
        SDAIbalance,
        addressQD,
        addressSDAI,
        notifications,
        mo,
        SECONDS_IN_DAY,
        choiseButton,
        chooseButton,
        setSwipe,
        swipeStatus
      }}
    >
      {children}
    </AppContext.Provider>
  )
}

export const useAppContext = () => useContext(AppContext)

export default AppContext
