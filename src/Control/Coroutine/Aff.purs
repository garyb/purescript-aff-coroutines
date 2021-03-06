-- | This module defines functions for creating coroutines on top of the `Aff` monad.
-- | 
-- | The `Aff` monad only supports actions which return a single value, asynchronously, so this
-- | module provides a principled way to deal with asynchronous _streams_ of values, and asynchronous consumers
-- | of streamed data.

module Control.Coroutine.Aff where

import Prelude

import Data.Maybe
import Data.Either
import Data.Functor (($>))
    
import Control.Coroutine
import Control.Monad.Eff (Eff())
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.Aff (Aff(), runAff)
import Control.Monad.Aff.AVar (AVar(), AVAR(), makeVar, takeVar, putVar)
import Control.Monad.Trans (lift)
    
-- | Create a `Producer` using an asynchronous callback.
-- |
-- | The callback should provide zero or more values of type `a`, which will be 
-- | emitted by the `Producer`, terminated by an optional value of type `r`. No values
-- | should be provided after a value of type `r` has been provided.
-- | 
-- | For example:
-- |
-- | ```purescript
-- | produce \emit -> do
-- |   log "Working..."
-- |   emit (Left "progress")
-- |   log "Done!"
-- |   emit (Right "finished")
-- | ```
produce :: forall a r eff. ((Either a r -> Eff (avar :: AVAR | eff) Unit) -> Eff (avar :: AVAR | eff) Unit) -> Producer a (Aff (avar :: AVAR | eff)) r
produce recv = do
  v <- lift makeVar
  lift $ liftEff $ recv $ runAff (const (return unit)) return <<< putVar v
  producer (takeVar v)
