Config = {}

Config.devMode = false

Config.WebHook = true
Config.WebhookTitle = 'Bcc-SellNpc'
Config.WebhookLink = ''  -- Discord WH link Here
Config.WebhookAvatar = '' -- must be 30x30px

Config.defaultlang = 'ro_lang'

-- List of items to check with respective prices
Config.itemsForSell = {
    {name = "coal", price = 1},
    {name = "water", price = 1},
    {name = "alcohol", price = 1},
    {name = "acid", price = 1}
    
}

-- Define allowed ped types that players can interact with
Config.AllowedPedTypes = {4, 5, 24, 6}

Config.alertPermissions = {
    ["illegalReport"] = {
        allowedJobs = {
            police = {minGrade = 0, maxGrade = 5}
        },
        blipSettings = {
            blipLabel = "Alert for illegal business",
            blipSprite = 'blip_ambient_companion',  -- Use actual sprite name or hash
            blipScale = 1.2,
            blipColor = 38,  -- Typically represents color ID
            blipDuration = 60000,  -- Time in milliseconds
            gpsRouteDuration = 60000  -- Time in milliseconds for GPS route
        }
    }
}
