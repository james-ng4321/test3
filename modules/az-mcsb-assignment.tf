#Microsoft Defender for Cloud Security Center Contact Assignment
#Require Owner Access to the Subscription

resource "azurerm_security_center_contact" "main" {
  for_each = {
    for index, security_center_contact in coalesce(var.security_center_contacts, []) : security_center_contact.email => security_center_contact
  }
  name                = each.value.name
  email               = each.value.email
  phone               = each.value.phone
  alert_notifications = each.value.alert_notifications
  alerts_to_admins    = each.value.alerts_to_admins
}