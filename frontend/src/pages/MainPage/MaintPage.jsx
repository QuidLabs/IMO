import React from 'react'

import { SideBar } from '../../components/Adds/SideBar'
import { Mint } from '../../components/Mint'

import './MaintPage.scss'

const MaintPage = () => {
  return (
    <React.Fragment>
      <div className="main-side">
        <SideBar />
      </div>
      <div className="main-content">
        <div className="main-mintContainer">
          <Mint />
        </div>
      </div>
      <div className="main-fakeCol" />
    </React.Fragment>
  )
}

export default MaintPage