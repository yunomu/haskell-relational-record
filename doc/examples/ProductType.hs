{-# LANGUAGE TemplateHaskell, MultiParamTypeClasses #-}
{-# LANGUAGE TypeSynonymInstances, FlexibleInstances #-}

module ProductType where

import Prelude hiding (id)
import Database.Record.TH (derivingShow)

import DataSource (defineTable)

$(defineTable []
  "LEARNINGSQL" "product_type" [derivingShow])
