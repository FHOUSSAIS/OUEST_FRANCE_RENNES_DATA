SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSONOFFBUZZER
-- Paramètre d'entrée	: @vp_idTerm : Identifiant du terminal concerné par la commande
--			  @vp_etat : Nouvel état du buzzer (0 : extinction du buzzer, 1 : allumage du buzzer)
--		            @vp_duree        : Durée d'allumage du buzzer (uniquement pour une commande d'allumage) : de 1 à 999 en 1/10 de sec	
-- Paramètre de sortie	: Code de retour par défaut:
--			  - @CODE_OK :La commande s'est exécutée correctement.
--			  - @CODE_KO : Erreur decréation de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_ERREUR : Durée incorrecte
-- Descriptif		: Cette procédure permet de gérer le buzzer du terminal. 
-----------------------------------------------------------------------------------------
-- Date			: 01/07/2005
-- Auteur		: M.Crosnier
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_OSYSONOFFBUZZER]
	@vp_idTerm tinyint,
	@vp_etat bit,
	@vp_duree int = 0
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

-- définition des constantes
set @CODE_OK=0
set @CODE_ERREUR = 2

-- initialisation de la variable de code retour
set @v_codeRetour=@CODE_OK
if (@vp_etat = 1)
begin
  -- Allumage du buzzer
  if ((@vp_duree>0) and (@vp_duree < 999))
  begin
    set @v_cmd = 'NbA'+dbo.SPV_CONVERTINTTOVARCHAR(@vp_duree, 3)
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd  
  end
  else begin
    -- Durée incohérente
    set @v_codeRetour = @CODE_ERREUR
  end
end
else begin
  -- Extinction du buzzer
  set @v_cmd = 'NbB'
  exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd    
end

return @v_codeRetour




