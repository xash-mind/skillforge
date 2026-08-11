type BrandMarkProps = {
  compact?: boolean;
};

export function BrandMark({ compact = false }: BrandMarkProps) {
  return (
    <span className="brand-mark" aria-label="SkillForge">
      <span className="brand-mark__symbol" aria-hidden="true">
        <span />
        <span />
        <span />
      </span>
      {compact ? null : <span className="brand-mark__wordmark">SkillForge</span>}
    </span>
  );
}
