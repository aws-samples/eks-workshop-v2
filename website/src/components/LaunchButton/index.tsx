import React, { type ReactNode } from "react";
import clsx from "clsx";

import styles from "./styles.module.css";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faArrowUpRightFromSquare } from "@fortawesome/free-solid-svg-icons";

interface Props {
  url: string;
  label: string;
}

export default function BrowserWindow({
  url = "http://localhost:3000",
  label = "Launch",
}: Props): JSX.Element {
  return (
    <a className={styles.button} href={url} target="_blank">
      {label}{" "}
      <FontAwesomeIcon
        className={styles.icon}
        icon={faArrowUpRightFromSquare}
      />
    </a>
  );
}
