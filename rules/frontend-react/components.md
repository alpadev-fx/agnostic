---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---
# React Component Conventions

## Component Patterns
- Functional components ONLY — no class components
- Hooks for state, side effects, refs, context
- One component per file (named export matching filename)
- Styling: CSS Modules / Tailwind / styled-components — pick one per project

## Hooks Rules
- Top-level only — no conditional `useState`/`useEffect`
- Custom hooks: prefix `use`, return tuple or object
- Dependencies arrays must be complete (use eslint-plugin-react-hooks)

## State Management
- Component state: `useState` / `useReducer`
- Cross-component: Context for low-frequency, Redux/Zustand/Jotai for high-frequency
- Server state: React Query / SWR (don't put it in Redux)

## Performance
- `useMemo` only when measured to help — premature memoization costs
- `useCallback` for callbacks passed to memoized children
- `React.memo` for components that re-render unnecessarily
- Avoid inline object/array props on hot components (new ref each render)
- Code-split heavy routes with `React.lazy` + `Suspense`

## Forms
- Formik / React Hook Form + Zod/Yup validation
- Controlled inputs for instant validation, uncontrolled for performance

## Testing
- React Testing Library — query by accessibility (role, label) not by class
- `data-testid` only as last resort
- Test user behavior, not implementation
- Wrap async in `await waitFor()` — not `setTimeout`

## Routing
- React Router v6+ for new projects
- Match the version the project is on — DON'T mix

## Anti-patterns
- Class components in new code
- Direct DOM manipulation (`document.getElementById`)
- `useEffect` for derived state (compute it instead)
- `useEffect` that fetches on mount without cleanup
- Setting state in render
