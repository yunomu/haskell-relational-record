{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- |
-- Module      : Database.HDBC.TH
-- Copyright   : 2013 Kei Hibino
-- License     : BSD3
--
-- Maintainer  : ex8k.hibino@gmail.com
-- Stability   : experimental
-- Portability : unknown
--
-- This module contains templates to generate Haskell record types
-- and instances correspond to RDB table schema.
module Database.HDBC.TH (
  defineWithTableDefault',
  defineWithTableDefault,

  defineTableFromDB
  ) where

import Data.Maybe (listToMaybe)
import Data.List (elemIndex)

import Database.HDBC (IConnection, SqlValue)

import Language.Haskell.TH.Name.CamelCase (ConName)
import Language.Haskell.TH (Q, runIO, TypeQ, Dec)

import Database.HDBC.Session (withConnectionIO)
import qualified Database.Relational.Query.TH as Relational
import Database.HDBC.Record.Persistable ()

import Database.HDBC.Schema.Driver (Driver, getFields, getPrimaryKey)


defineWithTableDefault' :: String -> String -> [(String, TypeQ)] -> [ConName] -> Q [Dec]
defineWithTableDefault' =  Relational.defineWithTableDefault' [t| SqlValue |]

defineWithTableDefault  :: String -> String -> [(String, TypeQ)] -> [ConName] -> Maybe Int -> Maybe Int -> Q [Dec]
defineWithTableDefault  =  Relational.defineWithTableDefault  [t| SqlValue |]

putLog :: String -> IO ()
putLog =  putStrLn

defineTableFromDB :: IConnection conn
                  => IO conn
                  -> Driver conn
                  -> String
                  -> String 
                  -> [ConName]
                  -> Q [Dec]
defineTableFromDB connect drv scm tbl derives = do
  let getDBinfo =
        withConnectionIO connect
        (\conn ->  do
            (cols, notNullIdxs) <- getFields drv conn scm tbl
            mayPrimaryKey       <- getPrimaryKey drv conn scm tbl

            mayPrimaryIdx <- case mayPrimaryKey of
              Just key -> case elemIndex key $ map fst cols of
                Nothing -> do putLog $ "defineTableFromDB: fail to find index of pkey - " ++ key ++ ". Something wrong!!"
                              return   Nothing
                Just ix ->    return $ Just ix
              Nothing  ->     return   Nothing
            return (cols, notNullIdxs, mayPrimaryIdx) )

  (cols, notNullIdxs, mayPrimaryIdx) <- runIO getDBinfo
  defineWithTableDefault scm tbl cols derives mayPrimaryIdx (listToMaybe notNullIdxs)
