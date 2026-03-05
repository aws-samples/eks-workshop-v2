import React, { type ReactNode } from "react";

import { translate } from "@docusaurus/Translate";

const title = translate({
  id: "time.estimatedTimeRequired",
});

const minutes = translate({
  id: "time.minutes",
});

interface Props {
  totalTime: string;
}

export default function RequiredTime({ totalTime }: Props): JSX.Element {
  return (
    <p>
      ⏱️ <b>{title}:</b> {totalTime} {minutes}
    </p>
  );
}
