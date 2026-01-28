import * as React from 'react'
import { Slot } from '@radix-ui/react-slot'

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  asChild?: boolean
  variant?: 'default' | 'primary' | 'secondary' | 'ghost'
}

const variantStylesMap = {
  default: [
    'bg-[var(--color-surface)]',
    'text-[var(--color-text)]',
    'border border-[var(--color-border)]',
    'hover:bg-[var(--color-border)]',
    'active:scale-[0.98]',
  ],
  primary: [
    'bg-[var(--color-primary)]',
    'text-white',
    'hover:bg-[var(--color-primary-hover)]',
    'active:scale-[0.98]',
    'shadow-sm',
    'hover:shadow-md',
  ],
  secondary: [
    'bg-transparent',
    'text-[var(--color-text)]',
    'border border-[var(--color-border)]',
    'hover:bg-[var(--color-surface)]',
    'active:scale-[0.98]',
  ],
  ghost: [
    'bg-transparent',
    'text-[var(--color-text)]',
    'hover:bg-[var(--color-border)]',
    'active:scale-[0.98]',
  ],
} as const

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'default', asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : 'button'

    const baseStyles = [
      'inline-flex items-center justify-center gap-2',
      'rounded-md font-medium text-sm',
      // Use CSS variables for motion duration
      'transition-fast',
      'will-change-transform',
      'focus-visible:outline-2 focus-visible:ring-2 focus-visible:ring-offset-2',
      'focus-visible:ring-[var(--color-primary)]',
      'disabled:pointer-events-none disabled:opacity-50',
      'disabled:active:scale-100', // Don't scale when disabled
      'disabled:shadow-none', // Remove shadow when disabled
      'min-h-[36px] px-4 py-2', // Fitts's Law: 36px min touch target
    ]

    const variantStyles = variantStylesMap[variant]

    return (
      <Comp
        ref={ref}
        className={[...baseStyles, ...variantStyles, className].filter(Boolean).join(' ')}
        {...props}
      />
    )
  }
)

Button.displayName = 'Button'
