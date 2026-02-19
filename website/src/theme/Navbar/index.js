import React from 'react';
import Navbar from '@theme-original/Navbar';
import SecondaryNav from '@site/src/components/SecondaryNav';

export default function NavbarWrapper(props) {
  return (
    <>
      <Navbar {...props} />
      <SecondaryNav />
    </>
  );
}
