SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEVTCODEABARRESTERMINAL
-- Paramètre d'entrée	: @vp_idTerm : Numéro du terminal où a été effectué la lecture du code à barres
--		           @vp_msg : Code à barres lu
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK: Traitement de la lecture effectué
--			  - @CODE_KO_ACTION_INCORRECTE_1: Etat de départ inconnu ou transition inconnue
--			  - @CODE_KO_ACTION_INCORRECTE_2 :Etat d'arrivé inconnu ou de type automate incompatible
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_KO_INCORRECT : Id d'écran inconnu
--			  - @CODE_ERREUR : Erreur d'exécution de traitement ou stockage de valeur saisie incorrecte
-- Descriptif		: Cette procédure traite une lecture de code à barres
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

CREATE PROCEDURE [dbo].[SPV_OSYSEVTCODEABARRESTERMINAL]
	@vp_idTerm tinyint,
	@vp_msg varchar (120)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_codeRetour integer
declare @v_idCaB tinyint
declare @v_idAutomate tinyint
declare @v_idTraitCaB tinyint
declare @v_idTransition tinyint
declare @v_eval SPVBoolean

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_ERREUR tinyint

--définition des constantes
set @CODE_OK = 0
set @CODE_ERREUR = 2

-- initialisation de la variable code de retour
set @v_codeRetour=@CODE_OK

BEGIN TRAN

-- Récuperation de l'identifiant de gestion CAB pour l'état en cours du terminal
select @v_idCaB = OEC_CAB from OSYS_TERMINAL, OSYS_AUTOMATE_TERMINAL, OSYS_ETAT_AUTOMATE, OSYS_ECRAN
where OTO_ID = @vp_idTerm and OTO_AUTOMATE = OAT_ID and OAT_ETAT_CRT = OEA_ID and OEA_ECRAN = OEC_ID

if (@v_idCaB is not null)
begin
  -- Une gestion de lecture de code à barres est paramétrée pour l'état du terminal
  -- Sauvegarde du code à barre lu
  select @v_idAutomate = OAT_ID from OSYS_TERMINAL, OSYS_AUTOMATE_TERMINAL where OTO_ID = @vp_idTerm and OTO_AUTOMATE = OAT_ID
  update OSYS_CAB_VALUE set OCV_VALUE = @vp_msg where OCV_AUTOMATE = @v_idAutomate and OCV_CAB = @v_idCaB
  if (@@ROWCOUNT > 0)
  begin
    select @v_eval = OCB_EVAL from OSYS_CODE_A_BARRES where OCB_ID = @v_idCaB
    -- Test du mode d'évaluation du traitement du code à barres
    if (@v_eval = 'N')
    begin
      -- le champ OCB_TRAITEMENT contient le numéro de la transition à exécuter
      select @v_idTransition = OCB_TRAITEMENT from OSYS_CODE_A_BARRES where OCB_ID = @v_idCaB
      -- exécution de la transition vers le nouvel état
      exec @v_codeRetour = SPV_OSYSEXECUTETRANSITION @v_idTransition, @vp_idTerm
    end
    else begin
      -- le champ OCB_TRAITEMENT contient l'id du traitement permettant d'obtenir le numéro de transition
      select @v_idTraitCaB = OCB_TRAITEMENT from OSYS_CODE_A_BARRES where OCB_ID = @v_idCaB	
      -- exécution du traitement permettant de calculer le prochain état
      exec @v_idTransition = SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitCaB
      if (@v_idTransition > 0)
      begin
        -- Une transition a été calculé, on exécute la transition
        exec @v_codeRetour = SPV_OSYSEXECUTETRANSITION @v_idTransition, @vp_idTerm   
      end
      else begin
        set @v_codeRetour = @CODE_ERREUR
      end
    end
  end
  else begin
    -- La sauvegarde du code à barres lu n'a pas pu être effectuée
    set @v_codeRetour = @CODE_ERREUR
  end
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


