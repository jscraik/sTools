import { useState, useEffect } from "react"

interface AnimatedCheckboxProps {
  checked: boolean
  onChange: () => void
  label: React.ReactNode
  id?: string
}

export function AnimatedCheckbox({ checked, onChange, label, id }: AnimatedCheckboxProps) {
  const [isAnimating, setIsAnimating] = useState(false)
  
  const handleClick = () => {
    setIsAnimating(true)
    onChange()
  }
  
  useEffect(() => {
    if (isAnimating) {
      const timer = setTimeout(() => setIsAnimating(false), 300)
      return () => clearTimeout(timer)
    }
  }, [isAnimating])

  return (
    <label 
      htmlFor={id}
      className="flex items-center gap-2.5 text-sm cursor-pointer group select-none"
    >
      <div className="relative flex items-center justify-center">
        {/* Hidden native checkbox for accessibility */}
        <input
          id={id}
          type="checkbox"
          checked={checked}
          onChange={handleClick}
          className="sr-only"
        />
        
        {/* Custom checkbox */}
        <div 
          className={`w-5 h-5 rounded border-2 transition-all duration-200 flex items-center justify-center
            ${checked 
              ? "bg-[var(--color-primary)] border-[var(--color-primary)]" 
              : "bg-[var(--color-background)] border-[var(--color-border)] group-hover:border-[var(--color-primary)]/50"
            }
            ${isAnimating ? "scale-110" : "scale-100"}
          `}
        >
          {/* Checkmark with animation */}
          <svg
            className={`w-3 h-3 text-white transition-all duration-200 ${
              checked 
                ? "opacity-100 scale-100" 
                : "opacity-0 scale-50"
            }`}
            viewBox="0 0 12 12"
            fill="none"
          >
            <path
              d="M2 6L5 9L10 3"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
              className={`${isAnimating && checked ? "animate-checkmark-draw" : ""}`}
              style={{
                strokeDasharray: 20,
                strokeDashoffset: checked ? 0 : 20,
                transition: "stroke-dashoffset 0.2s ease-out",
              }}
            />
          </svg>
        </div>
        
        {/* Ripple effect on check */}
        {isAnimating && checked && (
          <span className="absolute inset-0 rounded animate-ping opacity-20 bg-[var(--color-primary)]" />
        )}
      </div>
      
      <span className="transition-colors duration-200 group-hover:text-[var(--color-text)]">
        {label}
      </span>
    </label>
  )
}
