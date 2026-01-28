import * as React from 'react'
import * as SeparatorPrimitive from '@radix-ui/react-separator'

const orientationClassNames = {
  horizontal: 'h-[1px] w-full',
  vertical: 'h-full w-[1px]',
} as const

export const Separator = React.forwardRef<
  React.ElementRef<typeof SeparatorPrimitive.Root>,
  React.ComponentPropsWithoutRef<typeof SeparatorPrimitive.Root> & {
    orientation?: 'horizontal' | 'vertical'
  }
>(({ className, orientation = 'horizontal', decorative = true, ...props }, ref) => (
  <SeparatorPrimitive.Root
    ref={ref}
    decorative={decorative}
    orientation={orientation}
    className={[
      'shrink-0 bg-[var(--color-border)]',
      orientationClassNames[orientation],
      className,
    ]
      .filter(Boolean)
      .join(' ')}
    {...props}
  />
))

Separator.displayName = SeparatorPrimitive.Root.displayName
