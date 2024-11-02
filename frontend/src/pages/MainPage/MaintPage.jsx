import React from 'react'

import { MintBar } from '../../components/MintBar'
import { DepositeBar } from '../../components/DepositeBar'
import { Mint } from '../../components/Mint'

import './MaintPage.scss'

const MaintPage = () => {
  return (
    <React.Fragment>
      <div className="main-side">
        <MintBar />
      </div>
      <div className="main-content">
        <div className="main-mintContainer">
          <Mint />
        </div>
      </div>
      <div className="main-fakeCol" />
      <div className="main-side">
        <DepositeBar />
      </div>
    </React.Fragment>
  )
}

export default MaintPage