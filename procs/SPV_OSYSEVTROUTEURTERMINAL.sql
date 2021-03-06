SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEVTROUTEURTERMINAL
-- Paramètre d'entrée	: @vp_idAutomate : Numéro de l'automate à faire transiter
--			  @vp_idTransition : Numéro de la transition à exécuter	
-- Paramètre de sortie : Code de retour par défaut
--			  - @CODE_OK: Transition effectuée correctement
--			  - @CODE_KO_ACTION_INCORRECTE_1: Etat de départ incorrect ou transition inconnue
--			  - @CODE_KO_ACTION_INCORRECTE_2 :Etat d'arrivé incorrect ou de type automate incompatible
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_KO_INCORRECT : Id d'écran inconnu
--			  - @CODE_ERREUR : Erreur d'exécution de traitement
-- Descriptif		: Cette procédure exécute une transition automate demandée par un message routeur
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 13/10/2005									
-- Auteur		: M. Crosnier
-- Libellé		: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_OSYSEVTROUTEURTERMINAL]
	@vp_idAutomate tinyint,
	@vp_idTransition int
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_idTerm tinyint
declare @v_retour int

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint

--définition des constantes
set @CODE_OK = 0

-- initialisation de la variable code de retour
set @v_retour=@CODE_OK
set @v_idTerm = 0

BEGIN TRAN

-- Récuperation du terminal associé à l'automate
select TOP 1 @v_idTerm = isNull(OTO_ID, 0) from OSYS_TERMINAL where OTO_AUTOMATE = @vp_idAutomate

-- Exécution de la transition demandée
exec @v_retour = SPV_OSYSEXECUTETRANSITION @vp_idTransition, @v_idTerm

if @v_retour=@CODE_OK
begin
  COMMIT TRAN
end
else
begin
  ROLLBACK TRAN
end

return @v_retour


