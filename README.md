# Home-Drive-Cleanup-Multiple-Domains
Used to cleanup H Drives for AD Users. Will search across multiple Domains and strip the domain Suffix added to the H Drive Folder.

A)	If the folder has a Domain Suffix, it is stripped
  a.	Checks this against AD, and check if ANYONE in AD has this folder in their homeDirectory attribute.
    i.	If someone does not, then it logs it and can delete it
    ii.	If someone does, then it checks to see if the user it found is Enabled
      1.	If enabled, Ignore the folder.
      2.	If disabled, delete the folder.

Change the following according to your needs:
- Domains (Replace Domain1, Domain2)
- Export CSV Location.
