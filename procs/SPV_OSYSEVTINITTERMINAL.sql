SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEVTINITTERMINAL
-- Paramètre d'entrée	: @vp_idTerm : Numéro du terminal initialisé
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK: Initialisation effectuée
--			  - @CODE_KO_ACTION_INCORRECTE_1: Etat de départ inconnu ou transition inconnue
--			  - @CODE_KO_ACTION_INCORRECTE_2 :Etat d'arrivé inconnu ou de type automate incompatible
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_KO_INCORRECT : Id d'écran inconnu
--			  - @CODE_ERREUR : Erreur d'exécution de traitement de message
-- Descriptif		: Cette procédure initialise l'automate du terminal et entre dans l'état initial
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 28/06/2005
-- Auteur		: M. Crosnier
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_OSYSEVTINITTERMINAL]
	@vp_idTerm tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_codeRetour integer
declare @v_etatInit tinyint
declare @v_idAutomate tinyint
declare @v_idTraitement tinyint

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint

--définition des constantes
set @CODE_OK = 0

-- initialisation de la variable code de retour
set @v_codeRetour=@CODE_OK

BEGIN TRAN

-- Traitement d'initialisation d'un terminal
select @v_etatInit = OAT_ETAT_INIT, @v_idAutomate = OAT_ID from OSYS_AUTOMATE_TERMINAL , OSYS_TERMINAL where OAT_ID = OTO_AUTOMATE and OTO_ID = @vp_idTerm

-- Appel du traitement d'initialisation si un traitement a été défini
select @v_idTraitement = isNull(OAT_TRAITEMENT_INIT, 0) from OSYS_AUTOMATE_TERMINAL where OAT_ID = @v_idAutomate
if (@v_idTraitement > 0)
begin
  exec SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitement
end

-- Exécution de la transition d'entrée dans l'état initial
exec @v_codeRetour = SPV_OSYSEXECUTETRANSITION 0, @vp_idTerm

-- Mise à jour des états de l'automate
if (@v_codeRetour = @CODE_OK)
begin
  update OSYS_AUTOMATE_TERMINAL set OAT_ETAT_CRT = @v_etatInit, OAT_ETAT_PREC = @v_etatInit where OAT_ID = @v_idAutomate
end

if @v_codeRetour=@CODE_OK
begin
  COMMIT TRAN
end
else
begin
  ROLLBACK TRAN
end

return @v_codeRetour


