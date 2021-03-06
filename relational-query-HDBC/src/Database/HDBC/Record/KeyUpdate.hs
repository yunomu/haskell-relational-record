{-# LANGUAGE FlexibleContexts #-}

-- |
-- Module      : Database.HDBC.Record.KeyUpdate
-- Copyright   : 2013 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- This module provides typed 'KeyUpdate' running sequence
-- which intermediate structres are typed.
module Database.HDBC.Record.KeyUpdate (
  PreparedKeyUpdate,

  prepare, prepareKeyUpdate,

  bindKeyUpdate,

  runPreparedKeyUpdate, runKeyUpdate
  ) where

import Database.HDBC (IConnection, SqlValue, Statement)
import qualified Database.HDBC as HDBC

import Database.Relational.Query
  (KeyUpdate, untypeKeyUpdate, updateValuesWithKey, Pi)
import qualified Database.Relational.Query as Query
import Database.Record (ToSql)

import Database.HDBC.Record.Statement
  (BoundStatement (BoundStatement, bound, params), executeNoFetch)


-- | Typed prepared key-update type.
data PreparedKeyUpdate p a =
  PreparedKeyUpdate
  {
    -- | Key to specify update target records.
    updateKey         :: Pi a p
    -- | Untyped prepared statement before executed.
  , preparedKeyUpdate :: Statement
  }

-- | Typed prepare key-update operation.
prepare :: IConnection conn
        => conn
        -> KeyUpdate p a
        -> IO (PreparedKeyUpdate p a)
prepare conn ku = fmap (PreparedKeyUpdate key) . HDBC.prepare conn $ sql  where
  sql = untypeKeyUpdate ku
  key = Query.updateKey ku

-- | Same as 'prepare'.
prepareKeyUpdate :: IConnection conn
                 => conn
                 -> KeyUpdate p a
                 -> IO (PreparedKeyUpdate p a)
prepareKeyUpdate =  prepare

-- | Typed operation to bind parameters for 'PreparedKeyUpdate' type.
bindKeyUpdate :: ToSql SqlValue a
              => PreparedKeyUpdate p a
              -> a
              -> BoundStatement ()
bindKeyUpdate pre a =
  BoundStatement { bound = preparedKeyUpdate pre, params = updateValuesWithKey key a }
  where key = updateKey pre

-- | Bind parameters, execute statement and get execution result.
runPreparedKeyUpdate :: ToSql SqlValue a
                     => PreparedKeyUpdate p a
                     -> a
                     -> IO Integer
runPreparedKeyUpdate pre = executeNoFetch . bindKeyUpdate pre

-- | Prepare insert statement, bind parameters,
--   execute statement and get execution result.
runKeyUpdate :: (IConnection conn, ToSql SqlValue a)
             => conn
             -> KeyUpdate p a
             -> a
             -> IO Integer
runKeyUpdate conn q a = prepareKeyUpdate conn q >>= (`runPreparedKeyUpdate` a)
