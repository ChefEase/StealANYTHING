--!strict

-- Safe launch defaults. Server services enforce these flags; the client may only
-- receive a presentation copy after the server has chosen effective values.
return table.freeze({
    PvpEnabled = false,
    MonetizationEnabled = false,
})
