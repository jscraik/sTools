import { useState, useEffect, useRef, type ReactNode } from "react"

type ContextMenuItem = {
  label: string
  shortcut?: string
  onClick: () => void
  disabled?: boolean
  separator?: false
} | {
  separator: true
  onClick?: () => void
  label?: never
  shortcut?: never
  disabled?: never
}

interface ContextMenuProps {
  children: ReactNode
  items: ContextMenuItem[]
}

export function ContextMenu({ children, items }: ContextMenuProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [position, setPosition] = useState({ x: 0, y: 0 })
  const menuRef = useRef<HTMLDivElement>(null)
  const triggerRef = useRef<HTMLDivElement>(null)

  const handleContextMenu = (e: React.MouseEvent) => {
    e.preventDefault()
    
    // Calculate position relative to viewport
    const x = e.clientX
    const y = e.clientY
    
    // Adjust if menu would go off screen
    const menuWidth = 200
    const menuHeight = items.length * 32 + 16
    
    setPosition({
      x: Math.min(x, window.innerWidth - menuWidth - 16),
      y: Math.min(y, window.innerHeight - menuHeight - 16),
    })
    
    setIsOpen(true)
  }

  const handleClickOutside = (e: MouseEvent) => {
    if (menuRef.current && !menuRef.current.contains(e.target as Node)) {
      setIsOpen(false)
    }
  }

  useEffect(() => {
    if (isOpen) {
      document.addEventListener("mousedown", handleClickOutside)
      return () => document.removeEventListener("mousedown", handleClickOutside)
    }
  }, [isOpen])

  const handleItemClick = (item: ContextMenuItem) => {
    if ('separator' in item && item.separator) {
      return // Separators are not clickable
    }
    if (!item.disabled && item.onClick) {
      item.onClick()
      setIsOpen(false)
    }
  }

  return (
    <div ref={triggerRef} onContextMenu={handleContextMenu} className="contents">
      {children}
      
      {isOpen && (
        <>
          {/* Backdrop */}
          <div 
            className="fixed inset-0 z-40"
            onClick={() => setIsOpen(false)}
          />
          
          {/* Menu */}
          <div
            ref={menuRef}
            className="fixed z-50 min-w-[180px] py-1.5 rounded-lg bg-[var(--color-surface)] border border-[var(--color-border)] shadow-lg animate-fade-in"
            style={{
              left: position.x,
              top: position.y,
            }}
          >
            {items.map((item, index) => (
              <div key={index}>
                {item.separator ? (
                  <div className="my-1 border-t border-[var(--color-border)]" />
                ) : (
                  <button
                    onClick={() => handleItemClick(item)}
                    disabled={item.disabled}
                    className={`w-full px-3 py-1.5 text-left text-sm flex items-center justify-between gap-4
                      ${item.disabled 
                        ? "opacity-50 cursor-not-allowed" 
                        : "hover:bg-[var(--color-primary)] hover:text-white cursor-pointer"
                      }
                      transition-colors duration-100`}
                  >
                    <span>{item.label}</span>
                    {item.shortcut && (
                      <kbd className="text-[10px] opacity-60 font-mono">
                        {item.shortcut}
                      </kbd>
                    )}
                  </button>
                )}
              </div>
            ))}
          </div>
        </>
      )}
    </div>
  )
}
