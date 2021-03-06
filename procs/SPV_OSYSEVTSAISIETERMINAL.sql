SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEVTSAISIETERMINAL
-- Paramètre d'entrée	: @vp_idTerm : Numéro du terminal où a été effectué la saisie
--			  @vp_msg : Chaine de caractères saisie	
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK: Traitement de la saisie effectué
--			  - @CODE_KO_ACTION_INCORRECTE_1: Etat de départ inconnu  ou transition inconnue
--			  - @CODE_KO_ACTION_INCORRECTE_2 :Etat d'arrivé inconnu ou de type automate incompatible
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit
--			  - @CODE_KO_INCORRECT : Id d'écran inconnu
--			  - @CODE_ERREUR : Erreur d'exécution de traitement ou stockage de la saisie incorrecte
-- Descriptif		: Cette procédure traite une saisie opérateur
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

CREATE PROCEDURE [dbo].[SPV_OSYSEVTSAISIETERMINAL]
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
declare @v_idSaisie tinyint
declare @v_idAutomate tinyint
declare @v_idTransition tinyint
declare @v_idTraitSaisie tinyint
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

-- Récuperation du traitement de la saisie
select @v_idSaisie = OSA_ID from OSYS_TERMINAL, OSYS_AUTOMATE_TERMINAL, OSYS_ETAT_AUTOMATE, OSYS_ECRAN, OSYS_SAISIE
where OTO_ID = @vp_idTerm and OTO_AUTOMATE = OAT_ID and OAT_ETAT_CRT = OEA_ID and OEA_ECRAN = OEC_ID and OEC_SAISIE = OSA_ID

if (@v_idSaisie is not null)
begin
  -- Un traitement de saisie a été paramétré pour cet écran
  select @v_idAutomate = OAT_ID from OSYS_TERMINAL, OSYS_AUTOMATE_TERMINAL where OTO_ID = @vp_idTerm and OTO_AUTOMATE = OAT_ID
  -- Enregistrement de la saisie
  update OSYS_SAISIE_VALUE set OSV_VALUE = @vp_msg where OSV_AUTOMATE = @v_idAutomate and OSV_SAISIE = @v_idSaisie
  if (@@ROWCOUNT > 0)
  begin
    select @v_eval = OSA_EVAL from OSYS_SAISIE where OSA_ID = @v_idSaisie
    -- Traitement de la saisie
    if (@v_eval = 'N')
    begin
      -- le champ OSA_TRAITEMENT contient le prochain état dans lequel entrer
      select @v_idTransition = OSA_TRAITEMENT from OSYS_SAISIE where OSA_ID = @v_idSaisie
      exec @v_codeRetour = SPV_OSYSEXECUTETRANSITION @v_idTransition, @vp_idTerm
    end
    else begin
      -- le champ OSA_TRAITEMENT contient l'id du traitement permettant d'obtenir la transition à exécuter
      select @v_idTraitSaisie = OSA_TRAITEMENT from OSYS_SAISIE where OSA_ID = @v_idSaisie	
      exec @v_idTransition = SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitSaisie
      if (@v_idTransition > 0)
      begin
        -- Un état suivant a été calculé
        exec @v_codeRetour = SPV_OSYSEXECUTETRANSITION @v_idTransition, @vp_idTerm   
      end
      else begin
        set @v_codeRetour = @CODE_ERREUR
      end
    end
  end
  else begin
    -- Sauvegarde de la saisie opérateur impossible
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


