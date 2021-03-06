-- |
-- Module      : Database.Relational.Query.Monad.Trans.RestrictingState
-- Copyright   : 2013 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- This module provides context definition for
-- "Database.Relational.Query.Monad.Trans.Restricting".
module Database.Relational.Query.Monad.Trans.RestrictingState (
  -- * Context of restriction
  RestrictContext,

  primeRestrictContext,

  addRestriction,

  restriction
  ) where

import Database.Relational.Query.Expr (Expr, fromJust, exprAnd)
import Database.Relational.Query.Component (QueryRestriction)


-- | Context type for Restrict.
newtype RestrictContext c = RestrictContext
                            { restriction' :: QueryRestriction c }

-- | Initial 'RestrictContext'.
primeRestrictContext :: RestrictContext c
primeRestrictContext =  RestrictContext Nothing

-- | Add restriction of 'RestrictContext'.
addRestriction :: Expr c (Maybe Bool) -> RestrictContext c -> RestrictContext c
addRestriction e1 ctx =
  ctx { restriction' = Just . uf . restriction' $ ctx }
  where uf  Nothing  = fromJust e1
        uf (Just e0) = e0 `exprAnd` fromJust e1

-- | Finalize context to extract accumulated restriction state.
restriction :: RestrictContext c -> QueryRestriction c
restriction =  restriction'
