local M = {}

-- Common Slack emoji mappings to Unicode
local emoji_map = {
  -- Smileys & People
  ['+1'] = '👍',
  thumbsup = '👍',
  ['-1'] = '👎',
  thumbsdown = '👎',
  smile = '😄',
  smiley = '😃',
  grinning = '😀',
  blush = '😊',
  relaxed = '☺️',
  wink = '😉',
  heart_eyes = '😍',
  kissing_heart = '😘',
  kissing_closed_eyes = '😚',
  kissing = '😗',
  kissing_smiling_eyes = '😙',
  stuck_out_tongue_winking_eye = '😜',
  stuck_out_tongue_closed_eyes = '😝',
  stuck_out_tongue = '😛',
  flushed = '😳',
  grin = '😁',
  pensive = '😔',
  relieved = '😌',
  unamused = '😒',
  disappointed = '😞',
  persevere = '😣',
  cry = '😢',
  joy = '😂',
  sob = '😭',
  sleepy = '😪',
  disappointed_relieved = '😥',
  cold_sweat = '😰',
  sweat_smile = '😅',
  sweat = '😓',
  weary = '😩',
  tired_face = '😫',
  fearful = '😨',
  scream = '😱',
  angry = '😠',
  rage = '😡',
  triumph = '😤',
  confounded = '😖',
  laughing = '😆',
  yum = '😋',
  mask = '😷',
  sunglasses = '😎',
  sleeping = '😴',
  dizzy_face = '😵',
  astonished = '😲',
  worried = '😟',
  frowning = '😦',
  anguished = '😧',
  smiling_imp = '😈',
  imp = '👿',
  open_mouth = '😮',
  grimacing = '😬',
  neutral_face = '😐',
  confused = '😕',
  hushed = '😯',
  no_mouth = '😶',
  innocent = '😇',
  smirk = '😏',
  expressionless = '😑',
  thinking = '🤔',
  face_with_rolling_eyes = '🙄',
  rolling_on_the_floor_laughing = '🤣',
  rofl = '🤣',
  slightly_smiling_face = '🙂',
  upside_down_face = '🙃',
  face_vomiting = '🤮',
  star_struck = '🤩',
  zany_face = '🤪',
  exploding_head = '🤯',
  eyes = '👀',

  -- Hearts & Symbols
  heart = '❤️',
  orange_heart = '🧡',
  yellow_heart = '💛',
  green_heart = '💚',
  blue_heart = '💙',
  purple_heart = '💜',
  black_heart = '🖤',
  broken_heart = '💔',
  heavy_heart_exclamation = '❣️',
  two_hearts = '💕',
  revolving_hearts = '💞',
  heartbeat = '💓',
  heartpulse = '💗',
  sparkling_heart = '💖',
  cupid = '💘',
  gift_heart = '💝',
  heart_decoration = '💟',

  -- Hand gestures
  ok_hand = '👌',
  hand = '✋',
  raised_hand = '✋',
  raised_hands = '🙌',
  open_hands = '👐',
  palms_up_together = '🤲',
  clap = '👏',
  pray = '🙏',
  handshake = '🤝',
  wave = '👋',
  call_me_hand = '🤙',
  muscle = '💪',
  middle_finger = '🖕',
  point_up = '☝️',
  point_up_2 = '👆',
  point_down = '👇',
  point_left = '👈',
  point_right = '👉',
  crossed_fingers = '🤞',
  v = '✌️',

  -- Objects & Symbols
  fire = '🔥',
  sparkles = '✨',
  star = '⭐',
  star2 = '🌟',
  boom = '💥',
  collision = '💥',
  zap = '⚡',
  white_check_mark = '✅',
  heavy_check_mark = '✔️',
  x = '❌',
  negative_squared_cross_mark = '❎',
  exclamation = '❗',
  question = '❓',
  grey_exclamation = '❕',
  grey_question = '❔',
  heavy_plus_sign = '➕',
  heavy_minus_sign = '➖',
  heavy_division_sign = '➗',
  ['100'] = '💯',
  tada = '🎉',
  confetti_ball = '🎊',
  balloon = '🎈',
  trophy = '🏆',
  medal = '🥇',
  second_place_medal = '🥈',
  third_place_medal = '🥉',
  crown = '👑',

  -- Tech & Office
  computer = '💻',
  keyboard = '⌨️',
  desktop_computer = '🖥️',
  printer = '🖨️',
  computer_mouse = '🖱️',
  trackball = '🖲️',
  joystick = '🕹️',
  clamp = '🗜️',
  minidisc = '💽',
  floppy_disk = '💾',
  cd = '💿',
  dvd = '📀',
  vhs = '📼',
  camera = '📷',
  camera_flash = '📸',
  video_camera = '📹',
  movie_camera = '🎥',
  film_projector = '📽️',
  film_strip = '🎞️',
  telephone_receiver = '📞',
  phone = '☎️',
  pager = '📟',
  fax = '📠',
  tv = '📺',

  -- Nature
  sun = '☀️',
  cloud = '☁️',
  rain_cloud = '🌧️',
  snowman = '⛄',
  comet = '☄️',
  rainbow = '🌈',

  -- Food
  coffee = '☕',
  tea = '🍵',
  beer = '🍺',
  beers = '🍻',
  wine_glass = '🍷',
  cocktail = '🍸',
  tropical_drink = '🍹',
  champagne = '🍾',
  pizza = '🍕',
  hamburger = '🍔',
  fries = '🍟',
  popcorn = '🍿',

  -- Activities
  soccer = '⚽',
  basketball = '🏀',
  football = '🏈',
  baseball = '⚾',
  tennis = '🎾',
  volleyball = '🏐',
  rugby_football = '🏉',

  -- Animals
  dog = '🐕',
  cat = '🐈',
  mouse = '🐭',
  hamster = '🐹',
  rabbit = '🐰',
  fox = '🦊',
  bear = '🐻',
  panda = '🐼',
  koala = '🐨',
  tiger = '🐯',
  lion = '🦁',
  cow = '🐮',
  pig = '🐷',
  frog = '🐸',
  monkey = '🐵',
  chicken = '🐔',
  penguin = '🐧',
  bird = '🐦',
  eagle = '🦅',
  duck = '🦆',
  owl = '🦉',
  unicorn = '🦄',
  bee = '🐝',
  bug = '🐛',
  butterfly = '🦋',
  snail = '🐌',
  shell = '🐚',
  beetle = '🐞',
  ant = '🐜',
  spider = '🕷️',
  scorpion = '🦂',
  crab = '🦀',
  snake = '🐍',
  turtle = '🐢',
  tropical_fish = '🐠',
  fish = '🐟',
  dolphin = '🐬',
  whale = '🐳',
  shark = '🦈',
  octopus = '🐙',

  -- Flags
  checkered_flag = '🏁',
  triangular_flag_on_post = '🚩',
  rainbow_flag = '🏳️‍🌈',
  pirate_flag = '🏴‍☠️',
}

-- Get emoji character from name
function M.get_emoji(name)
  -- Remove colons if present
  name = name:gsub('^:', ''):gsub(':$', '')

  -- Check direct mapping
  if emoji_map[name] then
    return emoji_map[name]
  end

  -- Try with underscores replaced by hyphens
  local hyphenated = name:gsub('_', '-')
  if emoji_map[hyphenated] then
    return emoji_map[hyphenated]
  end

  -- Try with hyphens replaced by underscores
  local underscored = name:gsub('-', '_')
  if emoji_map[underscored] then
    return emoji_map[underscored]
  end

  -- Return the original name in colons if not found
  return ':' .. name .. ':'
end

-- Format reaction display
function M.format_reaction(name, count)
  local emoji = M.get_emoji(name)
  if count and count > 1 then
    return emoji .. count
  else
    return emoji
  end
end

return M
