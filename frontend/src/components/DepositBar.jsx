import { useCallback, useEffect, useState } from "react"
import { useAppContext } from "../contexts/AppContext"

import "./Styles/MintBar.scss"
import "./Styles/DepositeBar.scss"

export const DepositBar = ({address = null}) => {
    const { getDepositInfo, resetAccounts,
        account, connected, quid, usde, addressQD, notifications } = useAppContext()

    const [workEthBalance, setWorkEth] = useState("")
    const [workUsdBalance, setWorkUsd] = useState("")
    const [wethEthBalance, setWethEth] = useState("")
    const [wethUsdBalance, setWethUsd] = useState("")
    const [price, setPrice] = useState("")

    const updatingInfo = useCallback(async () => {
        try {
            if (connected && account && quid && usde && addressQD) {
                const setAddress = address ? address : account

                await getDepositInfo(setAddress)
                    .then(info => {
                        setWorkEth(info.work_eth_balance)
                        setWorkUsd(info.work_usd_balance)
                        setWethEth(info.weth_eth_balance)
                        setWethUsd(info.weth_usd_balance)
                        setPrice(info.ethPrice)
                    })
            } else resetAccounts(true)
        } catch (error) {
            console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
        }
    }, [getDepositInfo, resetAccounts,
        account, addressQD, connected, usde, quid, address])

    useEffect(() => {
        try {
            updatingInfo()
        } catch (error) {
            console.error("Some problem with sale's start function: ", error)
        }
    }, [resetAccounts, updatingInfo, connected, notifications])

    return (
        <div className={ address ? `global-summary-root ${connected ? 'show' : 'hide'}` : `summary-root`} >
            <div className="summary-section">
                <div className="summary-title">{address ? null : "My "}ETH pledged:</div>
                <div className="summary-value">
                    Ξ{connected? parseFloat(Number(workEthBalance).toFixed(2)) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">
                <div className="summary-title">{address ? null : "My "}$ owed:</div>
                <div className="summary-value">
                    ${connected ? (address ? parseFloat(Number(price * workUsdBalance).toFixed(2)) 
                        : parseFloat(Number(workUsdBalance).toFixed(2))) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">   
                <div className="summary-title">{address ? null : "My "} ETH insured:</div>
                <div className="summary-value">
                    <span className="summary-value">Ξ{connected ? parseFloat(Number(wethEthBalance).toFixed(4)) : 0}</span>
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">
                <div className="summary-title">{address ? null : "My "} $ value of insured:</div>
                <div className="summary-value">
                    ${connected ? (address ? parseFloat(Number(price * wethUsdBalance).toFixed(2)) 
                        : parseFloat(Number(wethUsdBalance).toFixed(2))) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
        </div>
    )
}
