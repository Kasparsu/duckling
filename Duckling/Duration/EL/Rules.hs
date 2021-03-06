-- Copyright (c) 2016-present, Facebook, Inc.
-- All rights reserved.
--
-- This source code is licensed under the BSD-style license found in the
-- LICENSE file in the root directory of this source tree. An additional grant
-- of patent rights can be found in the PATENTS file in the same directory.


{-# LANGUAGE GADTs #-}
{-# LANGUAGE NoRebindableSyntax #-}
{-# LANGUAGE OverloadedStrings #-}

module Duckling.Duration.EL.Rules
  ( rules
  ) where

import Data.HashMap.Strict (HashMap)
import Data.String
import Data.Text (Text)
import Prelude
import qualified Data.HashMap.Strict as HashMap
import qualified Data.Text as Text

import Duckling.Dimensions.Types
import Duckling.Duration.Helpers
import Duckling.Duration.Types (DurationData (DurationData))
import Duckling.Numeral.Helpers (parseInt, parseInteger, integer)
import Duckling.Numeral.Types (NumeralData(..))
import Duckling.Regex.Types
import Duckling.Types
import qualified Duckling.Numeral.Types as TNumeral
import qualified Duckling.TimeGrain.Types as TG

numeralMap :: HashMap Text Int
numeralMap = HashMap.fromList
  [ ( "δι"          , 2  )
  , ( "δί"          , 2  )
  , ( "τρι"         , 3  )
  , ( "τρί"         , 3  )
  , ( "τετρ"        , 4  )
  , ( "πεντ"        , 5  )
  , ( "πενθ"        , 5  )
  , ( "εξ"          , 6  )
  , ( "επτ"         , 7  )
  , ( "εφτ"         , 7  )
  , ( "οκτ"         , 8  )
  , ( "οχτ"         , 8  )
  , ( "εννι"        , 9  )
  , ( "δεκ"         , 10 )
  , ( "δεκαπεντ"    , 15 )
  , ( "δεκαπενθ"    , 15 )
  , ( "εικοσ"       , 20 )
  , ( "εικοσιπεντ"  , 25 )
  , ( "εικοσιπενθ"  , 25 )
  , ( "τριαντ"      , 30 )
  , ( "τριανταπεντ" , 35 )
  , ( "τριανταπενθ" , 35 )
  , ( "σαραντ"      , 40 )
  , ( "σαρανταπεντ" , 45 )
  , ( "σαρανταπενθ" , 45 )
  , ( "πενηντ"      , 50 )
  , ( "πενηνταπετν" , 55 )
  , ( "πενηνταπετθ" , 55 )
  , ( "εξηντ"       , 60 )
  , ( "ενενηντ"     , 90 )
  -- The following are used as prefixes
  , ( "μιά"         , 1  )
  , ( "ενά"         , 1  )
  , ( "δυό"         , 2  )
  , ( "τρεισί"      , 3  )
  , ( "τεσσερισή"   , 4  )
  , ( "τεσσερσή"    , 4  )
  , ( "πεντέ"       , 5  )
  , ( "εξί"         , 6  )
  , ( "επτά"        , 7  )
  , ( "εφτά"        , 7  )
  , ( "οκτώ"        , 8  )
  , ( "οχτώ"        , 8  )
  , ( "εννιά"       , 9  )
  , ( "δεκά"        , 10 )
  , ( "εντεκά"      , 11 )
  , ( "δωδεκά"      , 12 )
  ]

timeGrainMap :: HashMap Text TG.Grain
timeGrainMap = HashMap.fromList
  [ ( "λεπτο" , TG.Minute )
  , ( "ωρο"   , TG.Hour   )
  , ( "μερο"  , TG.Day    )
  , ( "ήμερο" , TG.Day    )
  , ( "μηνο"  , TG.Month  )
  , ( "ετία"  , TG.Year   )
  , ( "ετίας" , TG.Year   )
  , ( "ετή"   , TG.Year   )
  , ( "ετέ"   , TG.Year   )
  , ( "χρονο" , TG.Year   )
  ]

ruleDurationQuarterOfAnHour :: Rule
ruleDurationQuarterOfAnHour = Rule
  { name = "quarter of an hour"
  , pattern =
    [ regex "(1/4\\s?((της )ώρας|ω)|ένα τέταρτο|ενός τετάρτου)"
    ]
  , prod = \_ -> Just . Token Duration $ duration TG.Minute 15
  }

ruleDurationHalfAnHour :: Rule
ruleDurationHalfAnHour = Rule
  { name = "half an hour"
  , pattern =
    [ regex "(1/2\\s?((της )?ώρας?|ω)|μισάωρου?)"
    ]
  , prod = \_ -> Just . Token Duration $ duration TG.Minute 30
  }

ruleNumeralWithGrain :: Rule
ruleNumeralWithGrain = Rule
  { name = "<number><grain> (one word)"
  , pattern =
    [ regex $ "(δ[ιί]|τρ[ιί]|τετρ|πεν[θτ]|εξ|ε[πφ]τ|ο[κχ]τ|εννι|δεκ|"
           ++ "δεκαπεν[θτ]|εικοσ|εικοσιπεν[θτ]|τριαντ|τριανταπεν[θτ]|σαραντ|"
           ++ "σαρανταπεν[θτ]|πενηντ|πενηνταπεν[θτ]|εξηντ|ενενηντ)[αά]?"
           ++ "(λεπτο|ωρο|ή?μερο|μηνο|ετία?|ετ[ήέ]|χρονο)ς?υ?"
    ]
  , prod = \tokens -> case tokens of
      ( Token RegexMatch (GroupMatch (m:g:_)) : _ ) ->
        (Token Duration .) . duration <$> HashMap.lookup g timeGrainMap
                                      <*> HashMap.lookup m numeralMap
      _ -> Nothing
  }

ruleDurationThreeQuartersOfAnHour :: Rule
ruleDurationThreeQuartersOfAnHour = Rule
  { name = "three-quarters of an hour"
  , pattern =
    [ regex "(3/4\\s?((της )ώρας|ω)|τρία τέταρτα|τριών τετάρτων)"
    ]
  , prod = \_ -> Just . Token Duration $ duration TG.Minute 45
  }

ruleNumeralQuotes :: Rule
ruleNumeralQuotes = Rule
  { name = "<integer> + '\""
  , pattern =
    [ Predicate isNatural
    , regex "(['\"])"
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral (NumeralData {TNumeral.value = v}):
       Token RegexMatch (GroupMatch (x:_)):
       _) -> case x of
         "'"  -> Just . Token Duration . duration TG.Minute $ floor v
         "\"" -> Just . Token Duration . duration TG.Second $ floor v
         _    -> Nothing
      _ -> Nothing
  }

ruleDurationNumeralMore :: Rule
ruleDurationNumeralMore = Rule
  { name = "<integer> more <unit-of-duration>"
  , pattern =
    [ Predicate isNatural
    , dimension TimeGrain
    , regex "ακόμα|λιγότερ[οη]"
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral nd:Token TimeGrain grain:_:_) ->
        Just . Token Duration . duration grain . floor $ TNumeral.value nd
      _ -> Nothing
  }

ruleDurationDotNumeralHours :: Rule
ruleDurationDotNumeralHours = Rule
  { name = "number.number hours"
  , pattern =
    [ regex "(\\d+),(\\d+)"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (h:m:_)):Token TimeGrain TG.Hour:_) -> do
        hh <- parseInteger h
        mnum <- parseInteger m
        let mden = 10 ^ Text.length m
        Just . Token Duration $ minutesFromHourMixedFraction hh mnum mden
      _ -> Nothing
  }

ruleHalfDuration :: Rule
ruleHalfDuration = Rule
  { name = "half a <grain>"
  , pattern =
    [ regex "μισ[ήό]ς?"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (_:Token TimeGrain g:_) -> Token Duration <$> timesOneAndAHalf g 0
      _ -> Nothing
  }

ruleDurationAndAHalf :: Rule
ruleDurationAndAHalf = Rule
  { name = "<integer> and a half <grain>"
  , pattern =
    [ Predicate isNatural
    , regex "και μισ[ήό]ς?"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (Token Numeral nd:_:Token TimeGrain grain:_) ->
        timesOneAndAHalf grain (floor $ TNumeral.value nd) >>=
        Just . Token Duration
      _ -> Nothing
  }

ruleDurationAndAHalfOneWord :: Rule
ruleDurationAndAHalfOneWord = Rule
  { name = "<integer-and-half> <grain>"
  , pattern =
    [ regex $ "(μιά|ενά|δυό|τρεισί|τεσσερι?σή|πεντέ|εξί|ε[πφ]τά|ο[κχ]τώ|εννιά|"
           ++ "δεκά|εντεκά|δωδεκά)μισ[ιη]ς?"
    , dimension TimeGrain
    ]
  , prod = \tokens -> case tokens of
      (Token RegexMatch (GroupMatch (num:_)):Token TimeGrain grain:_) ->
        HashMap.lookup num numeralMap >>=
        timesOneAndAHalf grain >>=
        Just . Token Duration
      _ -> Nothing
  }

ruleDurationPrecision :: Rule
ruleDurationPrecision = Rule
  { name = "about|exactly <duration>"
  , pattern =
    [ regex "(περίπου|πάνω κάτω|ακριβώς)"
    , dimension Duration
    ]
    , prod = \tokens -> case tokens of
        (_:token:_) -> Just token
        _ -> Nothing
  }

rules :: [Rule]
rules =
  [ ruleDurationQuarterOfAnHour
  , ruleDurationHalfAnHour
  , ruleNumeralQuotes
  , ruleDurationNumeralMore
  , ruleNumeralWithGrain
  , ruleDurationThreeQuartersOfAnHour
  , ruleDurationDotNumeralHours
  , ruleHalfDuration
  , ruleDurationAndAHalf
  , ruleDurationAndAHalfOneWord
  , ruleDurationPrecision
  ]
