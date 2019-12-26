{-# LANGUAGE OverloadedStrings #-}

module ChainwebApi.Types.Base64Url where

------------------------------------------------------------------------------
import           Control.Lens (over)
import           Data.Aeson
import           Data.Aeson.Lens
import           Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Base64.URL as B64U
import qualified Data.ByteString.Lazy as BL
import           Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
------------------------------------------------------------------------------
import           ChainwebApi.Types.MinerData
------------------------------------------------------------------------------

newtype Base64Url a = Base64Url { fromBase64Url :: a }
  deriving (Eq,Ord,Show)

instance FromJSON a => FromJSON (Base64Url a) where
  parseJSON = withText "Base64Url" $ \t ->
    case decodeB64UrlNoPaddingText t of
      Left e -> fail e
      Right bs -> either fail (pure . Base64Url) $
                    eitherDecode $ BL.fromStrict bs

decodeB64UrlNoPaddingText :: Text -> Either String ByteString
decodeB64UrlNoPaddingText = B64U.decode . T.encodeUtf8 . pad
  where
    pad t = let s = T.length t `mod` 4 in t <> T.replicate ((4 - s) `mod` 4) "="

data Block = Block
  { blockHeight :: Int
  , blockChain  :: Int
  , blockMiner  :: MinerData
  } deriving (Eq,Ord,Show)

instance FromJSON Block where
  parseJSON = withObject "Block" $ \o -> Block
    <$> o .: "height"
    <*> o .: "chainId"
    <*> (parseJSON =<< fmap baz (o .: "minerData"))

getBlocks :: IO [Block]
getBlocks = do
  bs <- BS.readFile "/Users/doug/chainweb-dbs/minerData2.json"
  return $ magic bs

magic :: ByteString -> [Block]
magic bs = case eitherDecodeStrict bs of
             Left _  -> error "huetonaehonu"
             Right a -> a

bar :: ByteString -> [Value]
bar bs = case decodeStrict bs of
           Nothing -> error "failure decoding"
           Just a  -> map (over (key "minerData") baz) a

baz :: Value -> Value
baz (String t) = either (error "aoeuhtnaoehtn") id $ eitherDecodeStrict =<< decodeB64UrlNoPaddingText t
baz v = v

foo :: IO ByteString
foo = do
  bs <- BS.readFile "/Users/doug/chainweb-dbs/minerData2.json"
  --let t = decodeUtf8 bs
  --let hs = T.lines t
  return bs
