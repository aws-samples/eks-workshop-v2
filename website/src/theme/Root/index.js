import React from 'react';
import GlobalNotification from '../../components/GlobalNotification';

export default function Root({children}) {
  return (
    <>
      <GlobalNotification />
      {children}
    </>
  );
}