SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSONOFFVOYANT
-- Paramètre d'entrée	: @vp_idTerm : Identifiant du terminal concerné par la commande
--			  @vp_idVoyant : Identifiant du voyant 	
--			  @vp_etat : Nouvel état du voyant (0 : étient, 1 : allumé)
--			  @vp_duree :  Durée d'allumage du voyant (optionnel) de 0(infini) à 99 sec
-- Paramètre de sortie : Code de retour par défaut :
--			  - @CODE_OK :La commande s'est exécutée correctement.
--			  - @CODE_KO: Erreur decréation de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_ERREUR : Id de voyant incorrect
--			  - @CODE_KO_INCOMPATIBLE : erreur de durée d'allumage de voyant
-- Descriptif		: Cette procédure permet de gérer les voyants du terminal. 
-----------------------------------------------------------------------------------------
-- Date			: 01/07/2005
-- Auteur		: M.Crosnier
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_OSYSONOFFVOYANT]
	@vp_idTerm tinyint,
	@vp_idVoyant tinyint,
	@vp_etat bit,
	@vp_duree int=0
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- déclaration des variables
declare @v_codeRetour integer
declare @v_cmd varchar(120)

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_ERREUR tinyint
declare @CODE_KO_INCOMPATIBLE tinyint

-- définition des constantes
set @CODE_OK=0
set @CODE_ERREUR = 2
set @CODE_KO_INCOMPATIBLE = 14

-- initialisation de la variable de code retour
set @v_codeRetour=@CODE_OK

-- TODO : vérifier que le n° de voyant est cohérent

if (@vp_etat = 1)
begin
  -- Allumage du voyant
  if ((@vp_duree>=0) and (@vp_duree < 99))
  begin
    set @v_cmd = 'NSF'+dbo.SPV_CONVERTINTTOVARCHAR(@vp_idVoyant, 2)+dbo.SPV_CONVERTINTTOVARCHAR(@vp_etat, 1)+dbo.SPV_CONVERTINTTOVARCHAR(@vp_duree, 2)
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
  end
  else begin
    -- Durée incohérente
    set @v_codeRetour = @CODE_KO_INCOMPATIBLE
  end
end
else begin
  -- Extinction du buzzer
  set @v_cmd = 'NSF'+dbo.SPV_CONVERTINTTOVARCHAR(@vp_idVoyant, 2)+dbo.SPV_CONVERTINTTOVARCHAR(@vp_etat, 1)
  exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd    
end

return @v_codeRetour




