import React, { type ReactNode } from "react";
import clsx from "clsx";

import styles from "./styles.module.css";
import useBaseUrl from "@docusaurus/useBaseUrl";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { faArrowUpRightFromSquare } from "@fortawesome/free-solid-svg-icons";

interface Props {
  service: string;
  url: string;
  label: string;
}

export default function ConsoleButton({
  service,
  url = "http://localhost:3000",
  label = "Launch",
}: Props): JSX.Element {
  let serviceIcon = service || "console";
  return (
    <a className={styles.button} href={url} target="_blank">
      <img
        className={styles.icon}
        src={useBaseUrl(`/img/services/${serviceIcon}.png`)}
        alt="AWS console icon"
      />
      <span className={styles.label}>{label}</span>
    </a>
  );
}
