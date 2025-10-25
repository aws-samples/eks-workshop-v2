import React from "react";
import clsx from "clsx";
import { ThemeClassNames } from "@docusaurus/theme-common";
import { isActiveSidebarItem } from "@docusaurus/theme-common/internal";
import Link from "@docusaurus/Link";
import isInternalUrl from "@docusaurus/isInternalUrl";
import IconExternalLink from "@theme/Icon/ExternalLink";
import styles from "./styles.module.css";
export default function DocSidebarItemLink({
  item,
  onItemClick,
  activePath,
  level,
  index,
  ...props
}) {
  const { href, label, className, autoAddBaseUrl } = item;
  const isActive = isActiveSidebarItem(item, activePath);
  const isInternalLink = isInternalUrl(href);
  return (
    <li
      className={clsx(
        ThemeClassNames.docs.docSidebarItemLink,
        ThemeClassNames.docs.docSidebarItemLinkLevel(level),
        "menu__list-item",
        className,
      )}
      key={label}
    >
      <Link
        className={clsx(
          "menu__link",
          !isInternalLink && styles.menuExternalLink,
          {
            "menu__link--active": isActive,
          },
        )}
        autoAddBaseUrl={autoAddBaseUrl}
        aria-current={isActive ? "page" : undefined}
        to={href}
        {...(isInternalLink && {
          onClick: onItemClick ? () => onItemClick(item) : undefined,
        })}
        {...props}
      >
        <div className="category-wrapper">
          <div style={{ flex: "1" }}>{label}</div>
          <div>
            {item.customProps?.module ? (
              <span className="badge lab">LAB</span>
            ) : (
              <span></span>
            )}
            {item.customProps?.info ? (
              <span className="badge info">INFO</span>
            ) : (
              <span></span>
            )}
            {item.customProps?.explore ? (
              <span className="badge explore">EXPLORE</span>
            ) : (
              <span></span>
            )}
            {item.customProps?.optional ? (
              <span className="badge optional">OPTIONAL</span>
            ) : (
              <span></span>
            )}
          </div>
        </div>
        {!isInternalLink && <IconExternalLink />}
        {item.customProps?.explore && (
          <button
            aria-label={`Open external link for ${label}`}
            type="button"
            className="clean-btn menu__link"
            onClick={(e) => {
              e.stopPropagation();
              window.open(item.customProps.explore, "_blank", "noopener");
            }}
          >
            <IconExternalLink />
          </button>
        )}
      </Link>
    </li>
  );
}
