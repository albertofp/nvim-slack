---@meta

---@class SlackChannel
---@field id string
---@field name string
---@field is_im boolean
---@field is_mpim boolean
---@field user string?
---@field name_normalized string?
---@field has_unreads boolean?

---@class SlackMessage
---@field ts string
---@field user string
---@field text string
---@field type string
---@field subtype string?
---@field thread_ts string?
---@field reply_count number?
---@field reactions SlackReaction[]?

---@class SlackReaction
---@field name string
---@field count number
---@field users string[]?

---@class SlackSelectedMessage
---@field ts string
---@field user string
---@field text string
---@field index number
---@field reactions SlackReaction[]?
---@field thread_ts string?
---@field reply_count number?

return {}