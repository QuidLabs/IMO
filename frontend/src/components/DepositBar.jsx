import { useCallback, useEffect, useState } from "react"
import { useAppContext } from "../contexts/AppContext";
import { numberWithCommas } from "../utils/number-with-commas"

import "./Styles/MintBar.scss"
import "./Styles/DepositeBar.scss"

export const DepositBar = ({address = null}) => {
    const { getDepositInfo, resetAccounts,
        account, connected, quid, usde, addressQD, notifications } = useAppContext()

    const [workEthBalance, setWorkEth] = useState("")
    const [workUsdBalance, setWorkUsd] = useState("")
    const [wethEthBalance, setWethEth] = useState("")
    const [wethUsdBalance, setWethUsd] = useState("")

    const updatingInfo = useCallback(async () => {
        try {
            if (connected && account && quid && usde && addressQD) {
                const setAddress = address ? address : account

                await Promise.all([getDepositInfo(setAddress)])
                    .then(value => {
                        setWorkEth(value[0].work_eth_balance)
                        setWorkUsd(value[0].work_usd_balance)
                        setWethEth(value[0].weth_eth_balance)
                        setWethUsd(value[0].weth_usd_balance)
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
                    Ξ{connected? numberWithCommas(parseFloat(Number(workEthBalance).toFixed(2))) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">
                <div className="summary-title">{address ? null : "My "}$ owed:</div>
                <div className="summary-value">
                    ${connected ? numberWithCommas(parseFloat(Number(workUsdBalance).toFixed(2))) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">   
                <div className="summary-title">{address ? null : "My "} ETH insured:</div>
                <div className="summary-value">
                    <span className="summary-value">Ξ{connected ? parseFloat(Number(wethEthBalance).toFixed(2)) : 0}</span>
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">
                <div className="summary-title">{address ? null : "My "} $ value of insured:</div>
                <div className="summary-value">
                    ${connected ? parseFloat(Number(wethUsdBalance).toFixed(2)) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
        </div>
    )
}
