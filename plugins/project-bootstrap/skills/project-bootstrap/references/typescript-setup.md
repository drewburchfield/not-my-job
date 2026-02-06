# TypeScript/Node Quality Tooling Templates

## tsconfig.json

Only create if missing. Use this as a sensible default:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "outDir": "./dist"
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

If the project already has a `tsconfig.json`, do not overwrite it. Just verify `strict: true` is enabled and suggest turning it on if not.

## eslint.config.mjs (ESLint Flat Config)

```javascript
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  {
    ignores: ["dist/", "node_modules/", "*.js"],
  },
  {
    rules: {
      "@typescript-eslint/no-unused-vars": [
        "error",
        { argsIgnorePattern: "^_" },
      ],
      "@typescript-eslint/no-explicit-any": "warn",
    },
  }
);
```

### Install command

```bash
npm install --save-dev eslint @eslint/js typescript-eslint
```

If the project uses `yarn`, substitute `yarn add --dev`. Check for `yarn.lock` to determine package manager.

## .prettierrc

```json
{
  "semi": true,
  "singleQuote": false,
  "tabWidth": 2,
  "trailingComma": "all",
  "printWidth": 100
}
```

### Install command

```bash
npm install --save-dev prettier
```

## Quality Gate Commands

After setup, the quality gates for TypeScript projects are:

| Gate | Command |
|---|---|
| Type check | `npx tsc --noEmit` |
| Lint | `npx eslint .` |
| Format | `npx prettier --check .` |

## Package Manager Detection

Check in this order:
1. `bun.lockb` exists: use `bun`
2. `pnpm-lock.yaml` exists: use `pnpm`
3. `yarn.lock` exists: use `yarn`
4. Default: `npm`
