Config = {}

Config.devMode = false
Config.WebHook = true
Config.WebhookTitle = 'Bcc-SellNpc'
Config.WebhookLink = ''   -- Discord WH link Here
Config.WebhookAvatar = '' -- must be 30x30px
Config.defaultlang = 'ro_lang'
Config.Jobs = {
    lawEnforcement = {
        "police",
    },
    medical = {
        "doctor",

    },
    administration = {
        "mayor",
        "writer"
    }
}
-- Use references to centralized job definitions
Config.NoSellJobsEnable = true
Config.NoSellJobs = Config.Jobs.lawEnforcement -- Doctors are restricted from robbery
Config.RequiredJobEnble = true
Config.RequiredJobs = {
    Amount = 1,
    Jobs = Config.Jobs.lawEnforcement -- Law enforcement jobs required for an action
}
Config.SellLimitNoLawEnabled = true   -- Toggle sell limit feature when no law enforcement is online
Config.MaxSellsWithoutLaw = 5         -- Maximum sells allowed when no law enforcement is online

-- Payment system: "money" or "items"
Config.PaymentType = "items" -- Change to "money" for old money-based system

-- List of items to check with respective rewards
-- If PaymentType is "money", use price field
-- If PaymentType is "items", use rewardItems field
Config.itemsForSell = {
    { 
        name = "coal", 
        price = 1, -- Used when PaymentType = "money"
        rewardItems = { -- Used when PaymentType = "items"
            { name = "bread", amount = 2 },
            { name = "water", amount = 1 }
        }
    },
    { 
        name = "water", 
        price = 1, -- Used when PaymentType = "money"
        rewardItems = { -- Used when PaymentType = "items"
            { name = "bread", amount = 1 }
        }
    },
    { 
        name = "alcohol", 
        price = 1, -- Used when PaymentType = "money"
        rewardItems = { -- Used when PaymentType = "items"
            { name = "bread", amount = 3 },
            { name = "apple", amount = 2 }
        }
    },
    { 
        name = "acid", 
        price = 1, -- Used when PaymentType = "money"
        rewardItems = { -- Used when PaymentType = "items"
            { name = "bread", amount = 5 },
            { name = "water", amount = 3 },
            { name = "apple", amount = 1 }
        }
    }
}

-- Define allowed ped types that players can interact with
Config.AllowedPedTypes = { 4, 5, 24, 6 }
Config.alertPermissions = {
    ["illegalReport"] = {
        allowedJobs = {
            police = { minGrade = 0, maxGrade = 5 }
        },
        blipSettings = {
            blipLabel = "Alert for illegal business",
            blipSprite = 'blip_ambient_companion', -- Use actual sprite name or hash
            blipScale = 1.2,
            blipColor = 38,                        -- Typically represents color ID
            blipDuration = 60000,                  -- Time in milliseconds
            gpsRouteDuration = 60000               -- Time in milliseconds for GPS route
        }
    }
}
