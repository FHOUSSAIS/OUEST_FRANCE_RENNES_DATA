SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Procédure		: SPV_OSYSEXECUTEECRAN
-- Paramètre d'entrée	: @vp_idTerm : Numéro de terminal où exécuter l'écran
--			  @vp_idEcran : Numéro d'écran à exécuter
-- Paramètre de sortie	: Code de retour par défaut
--			  - @CODE_OK: Execution de l'écran OK
--			  - @CODE_KO: Erreur de création de commande
--			  - @CODE_KO_INCONNU : Id de terminal inconnu
--			  - @CODE_KO_INTERDIT : envoi d'une commande vide interdit, ou délai incohérent
--			  - @CODE_KO_INCORRECT : Id d'écran inconnu
--			  - @CODE_ERREUR : Erreur d'exécution de traitement de message
-- Descriptif		: Cette procédure exécute un écran. L'exécution comporte les éléments suivants
--			  * Application du paramétrage des touches de fonction
--			  * Raz de l'affichage si nécessaire
--			  * Affichage des messages du menu associé à l'écran
--			  * Affichage de la zone de saisie associée à l'écran
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

CREATE PROCEDURE [dbo].[SPV_OSYSEXECUTEECRAN]
	@vp_idTerm tinyint, 
	@vp_idEcran tinyint
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

--déclaration des variables
declare @v_codeRetour integer
declare @v_autFonction bit
declare @v_autRaz bit
declare @v_autBacklight bit
declare @v_cmd varchar(120)
declare @v_idSaisie tinyint
declare @v_saisieLigne tinyint
declare @v_saisieColonne tinyint
declare @v_saisieLongueur tinyint
declare @v_saisieTraduction int
declare @v_saisieEval SPVBoolean
declare @v_idMessage int
declare @v_msgMode tinyint
declare @v_msgLigne tinyint
declare @v_msgColonne tinyint
declare @v_msgLongueur int
declare @v_msgMessage varchar(120)
declare @v_msgEval SPVBoolean
declare @v_msgIdTraduction int
declare @v_msgLangue varchar(3)
declare @v_saisieLangue varchar(3)
declare @v_strLen varchar(3)
declare @v_saisieMessage varchar(120)
declare @v_ligneMax tinyint
declare @v_idTraitement tinyint
declare @v_autVide tinyint
declare @v_autCaB tinyint
declare @v_buzId tinyint
declare @v_buzEtat bit
declare @v_buzDuree int
declare @v_vytNum tinyint
declare @v_vytEtat bit
declare @v_vytDuree int
declare @v_numLigneEnCours int
declare @v_numColonneEnCours int
declare @v_msgActif SPVBoolean

-- déclaration des constantes de code retour 
declare @CODE_OK tinyint
declare @CODE_KO tinyint
declare @CODE_KO_INCORRECT tinyint
declare @CODE_ERREUR tinyint
declare @CODE_KO_INCONNU tinyint

DECLARE @local bit

--définition des constantes
set @CODE_OK = 0
set @CODE_KO = 1
set @CODE_KO_INCORRECT = 11
set @CODE_ERREUR = 2
set @CODE_KO_INCONNU = 7

-- initialisation de la variable code de retour
set @v_codeRetour=@CODE_OK
set @v_cmd=''
set @v_numLigneEnCours = 1
set @v_numColonneEnCours = 1

  -- Test si le numéro de terminal est cohérent
  if (not Exists (select 1 from OSYS_TERMINAL where OTO_ID = @vp_idTerm))
  begin
    -- Numéro de terminal inconnu
    set @v_codeRetour = @CODE_KO_INCONNU
  end
  
  -- Test si le numéro d'écran est cohérent
  if (@v_codeRetour = @CODE_OK)
  begin
    if (not Exists (select 1 from OSYS_ECRAN where OEC_ID = @vp_idEcran))
    begin
      -- Numéro d'écran inconnu
      set @v_codeRetour = @CODE_KO_INCORRECT
    end
  end

  -- Gestion du paramétrage des touches de fonctions
  if (@v_codeRetour = @CODE_OK)
  begin
    -- Si aucune fonction n'est définie pour l'écran, on désactive les touches de fonction
    if (Exists (select 1 from OSYS_FONCTION where OFO_ECRAN = @vp_idEcran))
    begin
      -- Au moins une fonctiondéfinie pour cet écran
      set @v_autFonction = 0
    end
    else begin
      -- Pas de fonction pour cet écran
      set @v_autFonction = 1
    end
    -- Envoi de la commande de paramétrage des fonctions
    set @v_cmd = 'NCA'+convert(varchar(1), 0)+convert(varchar(1), @v_autFonction)
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd    
  end

  -- Gestion du lecteur code à barres
  -- Si un traitement de lecture code à barre est défini pour l'écran, on autorise la lecture, sinon non
  if (@v_codeRetour = @CODE_OK)
  begin
    if (Exists (select 1 from OSYS_ECRAN where OEC_ID = @vp_idEcran and OEC_CAB <> NULL))
    begin
      -- Un traitement de code à barres est défini, on autorise la lecture
      set @v_autCaB = 0
    end
    else begin
      -- Pas de traitement de CaB défini, on interdit la lecture
      set @v_autCaB = 1
    end
    -- Envoi de la commande de paramétrage de la lecture code à barres
    set @v_cmd = 'NBA'+dbo.SPV_CONVERTINTTOVARCHAR(@v_autCaB, 1)
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
  end

  select @v_autRaz = OEC_RAZ, @v_autBacklight = OEC_BACKLIGHT from OSYS_ECRAN where OEC_ID = @vp_idEcran

  -- Gestion du Backlight
  if (@v_codeRetour = @CODE_OK)
  begin
    -- Le backlight est envoyé en décalé de 5sec dans le cas d'une extinction
    if (@v_autBacklight = 0)
    begin
      -- Extinction du backlight
      set @v_cmd = 'NRG050'+char(27)+'NAA'+dbo.SPV_CONVERTINTTOVARCHAR(@v_autBacklight, 1)
      exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
    end
    else begin
      -- Allumage du backlight
      set @v_cmd = 'NAA'+dbo.SPV_CONVERTINTTOVARCHAR(@v_autBacklight, 1)
      exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
    end
  end

  -- Gestion du RAZ
  if (@v_codeRetour = @CODE_OK)
  begin
    if (@v_autRaz > 0)
    begin
      set @v_cmd = 'NAG'
      exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
    end
  end

  -- Gestion du buzzer
  if (@v_codeRetour = @CODE_OK)
  begin
    select @v_buzId = isNull(OBU_ID, 0), @v_buzEtat = isNull(OBU_ETAT, 0), @v_buzDuree = isNull(OBU_DUREE, 0) from OSYS_ECRAN, OSYS_CMD_BUZZER where OEC_CMD_BUZZER = OBU_ID and OEC_ID = @vp_idEcran
    if (@v_buzId > 0)
    begin
      -- Une commande de buzzer est paramétrée pour cet écran
      exec @v_codeRetour = SPV_OSYSONOFFBUZZER @vp_idTerm, @v_buzEtat, @v_buzDuree
    end
  end

  -- Gestion des voyants
  if (@v_codeRetour = @CODE_OK)
  begin
    declare c_idVoyant CURSOR LOCAL FAST_FORWARD for
    select OVO_VOYANT, OVO_ETAT, OVO_DUREE from OSYS_CMD_VOYANT, OSYS_ASSOCIATION_VOYANT_ECRAN where OAV_ECRAN = @vp_idEcran and OAV_CMD_VOYANT = OVO_ID order by OAV_ORDRE asc
    -- ouverture du curseur
    open c_idVoyant
    fetch next from  c_idVoyant INTO @v_vytNum, @v_vytEtat, @v_vytDuree
    while ((@@FETCH_STATUS = 0) and (@v_codeRetour = @CODE_OK))
    begin
      exec @v_codeRetour = SPV_OSYSONOFFVOYANT @vp_idTerm, @v_vytNum, @v_vytEtat, @v_vytDuree
      fetch next from  c_idVoyant INTO @v_vytNum, @v_vytEtat, @v_vytDuree
    end
    -- fermeture du curseur
    close c_idVoyant
    deallocate c_idVoyant
  end

  -- Par défaut, la zone de saisie est positionnée sinon l'affichage de la première ligne n'est pas effectué 
  set @v_cmd = 'NAE9999'
  exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm, @v_cmd

  -- Gestion des messages à afficher
  if (@v_codeRetour = @CODE_OK)
  begin
     -- Calcul de la ligne d'affichage de la zone de saisie dans le cas d'un affichage au fil de l'eau
     set @v_saisieLigne = 0
     select @v_saisieLigne = isNull(OSA_LIGNE, 0) from OSYS_SAISIE, OSYS_ECRAN where OSA_ID = OEC_SAISIE and OEC_ID = @vp_idEcran

     declare c_idMessage CURSOR LOCAL FAST_FORWARD for
     select OAM_MESSAGE from OSYS_ASSOCIATION_MESSAGE_ECRAN, OSYS_MESSAGE where OAM_ECRAN = @vp_idEcran and OAM_MESSAGE = OME_ID order by OAM_ORDRE asc

     -- ouverture du curseur
     open c_idMessage

    fetch next from  c_idMessage INTO @v_idMessage
    while ((@@FETCH_STATUS = 0) and (@v_codeRetour = @CODE_OK))
    begin      
      -- affichage du message uniquement si le message est actif
      select @v_msgActif = OAM_ACTIF from OSYS_ASSOCIATION_MESSAGE_ECRAN where OAM_ECRAN = @vp_idEcran and OAM_MESSAGE = @v_idMessage
      if (@v_msgActif = 'O')
      begin
        select  @v_msgMode = OME_MODE, @v_msgLigne = OME_LIGNE, @v_msgColonne = OME_COLONNE, @v_msgLongueur = isNull(OME_LONGUEUR, 0), @v_msgEval = OME_EVAL from OSYS_MESSAGE where OME_ID = @v_idMessage
        if (@v_msgEval = 'N')
        begin
          -- Le champ OME_MESSAGE contient l'id de traduction de la chaine de caractères à afficher
          select @v_msgIdTraduction = OME_MESSAGE from OSYS_MESSAGE where OME_ID = @v_idMessage
        end
        else begin
          -- Le champ OME_MESSAGE contient le nom de la procédure stockée à exécuter pour obtenir la chaine de caractères à afficher
          select @v_idTraitement = OME_MESSAGE from OSYS_MESSAGE where OME_ID = @v_idMessage
          exec @v_msgIdTraduction = SPV_OSYSEXECUTETRAITEMENT @vp_idTerm, @v_idTraitement
          if (@v_msgIdTraduction = 0)
          begin
            -- Erreur d'exécution de traitement
            set @v_codeRetour = @CODE_ERREUR
            break
          end
        end
        -- Récuperation de la langue de l'utilisateur du terminal
        select @v_msgLangue = UTI_LANGUE from UTILISATEUR, OSYS_TERMINAL where OTO_UTILISATEUR = UTI_ID
        -- Récuperation du contenu du message à afficher
        set @v_msgMessage = dbo.INT_GETLIBELLE(@v_msgIdTraduction, @v_msgLangue)
        -- Paramétrage de la longueur du message
        if (@v_msgLongueur = 0)
        begin
          set @v_strLen = ''
        end
        else begin
          set @v_strLen = 'C'+dbo.SPV_CONVERTINTTOVARCHAR(@v_msgLongueur, 3)
        end
        -- Paramétrage de la position du message	
        if (@v_msgLigne = 0)
        begin
          -- Le message doit être affiché sur  la prochaine ligne sauf si la prochaine ligne est dédiée à une zone de saisie
          if (@v_numLigneEnCours  = @v_saisieLigne)
          begin
	set @v_msgLigne = @v_numLigneEnCours + 1
          end
          else begin
	set @v_msgLigne = @v_numLigneEnCours
          end
          set @v_numLigneEnCours = @v_msgLigne + 1 
        end
        else begin
         -- Le message doit être affiché sur une ligne définie
         set @v_numLigneEnCours  = @v_msgLigne + 1
        end
        if (@v_msgColonne = 0)
        begin
          -- Le message doit être affiché à partir de  la prochaine colonne
          set @v_msgColonne = @v_numColonneEnCours
          set @v_numColonneEnCours = @v_numColonneEnCours + 1 
        end
        else begin
          -- Le message doit être affiché à partir d'une colonne définie
          set @v_numColonneEnCours = @v_msgColonne + 1 
        end
        -- Envoi de la commande d'affichage du message
        set @v_cmd = 'NAOA'+dbo.SPV_CONVERTINTTOVARCHAR(@v_msgMode, 1)+'B'+dbo.SPV_CONVERTINTTOVARCHAR(@v_msgLigne, 2)+dbo.SPV_CONVERTINTTOVARCHAR(@v_msgColonne, 2)+@v_strLen+'D'+@v_msgMessage
        exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm, @v_cmd
        if (@v_codeRetour <> @CODE_OK)
        begin
          -- Erreur d'envoi de commande, on arrête le traitement des messages
          break
        end
      end
      fetch next from  c_idMessage INTO @v_idMessage     
    end
    -- fermeture du curseur
    close c_idMessage
    deallocate c_idMessage
  end

  -- Gestion de la zone de saisie
  select @v_idSaisie = isNull(OEC_SAISIE, 0) from OSYS_ECRAN where OEC_ID = @vp_idEcran
  if ((@v_idSaisie > 0) and (@v_codeRetour = @CODE_OK))
  begin
    -- Une zone de saisie est paramétrée pour l'écran
    -- Paramétrage de l'autorisation de saisie vide
    select @v_autVide = OSA_AUT_VIDE from OSYS_SAISIE where OSA_ID = @v_idSaisie
    -- Envoi de la commande de paramétrage de l'autorisation de saisie vide
    set @v_cmd = 'NCG'+dbo.SPV_CONVERTINTTOVARCHAR(@v_autVide, 1)
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
    
    -- Récuperation du paramétrage de la zone de saisie à afficher
    select @v_saisieLigne = OSA_LIGNE, @v_saisieColonne = OSA_COLONNE, @v_saisieLongueur = isNull(OSA_LONGUEUR, 0), @v_saisieTraduction = isNull(OSA_MESSAGE, 0), @v_saisieEval = OSA_EVAL from OSYS_SAISIE where OSA_ID = @v_idSaisie
    --Paramétrage de la longueur de la zone de saisie
    if (@v_saisieLongueur = 0)
    begin
      set @v_strLen = ''
    end
    else begin
      set @v_strLen = 'C'+dbo.SPV_CONVERTINTTOVARCHAR(@v_saisieLongueur, 2)
    end
    if (@v_saisieTraduction < 0)
    begin
      -- Le champ OSA_MESSAGE contient l'id de traduction de la chaine de caractères à afficher          
      -- Il y a un message à afficher
      select @v_saisieLangue = UTI_LANGUE from UTILISATEUR, OSYS_TERMINAL where OTO_UTILISATEUR = UTI_ID
      set @v_saisieMessage = dbo.INT_GETLIBELLE(@v_saisieTraduction, @v_saisieLangue)
    end
    else begin
      set @v_saisieMessage = ''
    end
    -- Paramétrage de la position de la zone de saisie
    if (@v_saisieLigne = 0)
    begin
      -- Le message doit être affiché sur  la prochaine ligne
      set @v_saisieLigne = @v_numLigneEnCours
      set @v_numLigneEnCours = @v_numLigneEnCours + 1 
    end
    else begin
      -- Le message doit être affiché sur une ligne définie
      set @v_numLigneEnCours  = @v_saisieLigne + 1
    end
    if (@v_saisieColonne = 0)
    begin
      -- Le message doit être affiché à partir de  la prochaine colonne
      set @v_saisieColonne = @v_numColonneEnCours
      set @v_numColonneEnCours = @v_numColonneEnCours + 1 
    end
    else begin
      -- Le message doit être affiché à partir d'une colonne définie
      set @v_numColonneEnCours = @v_saisieColonne + 1 
    end
    -- Envoi de la commande de définition de la fenêtre de saisie
    set @v_cmd = 'NAQB'+dbo.SPV_CONVERTINTTOVARCHAR(@v_saisieLigne, 2)+dbo.SPV_CONVERTINTTOVARCHAR(@v_saisieColonne+LEN(@v_saisieMessage)+1, 2)+@v_strLen
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
    -- Envoi de la commande d'affichage du message de la zone de saisie
    set @v_cmd = 'NAOA2B'+dbo.SPV_CONVERTINTTOVARCHAR(@v_saisieLigne, 2)+dbo.SPV_CONVERTINTTOVARCHAR(@v_saisieColonne, 2)+'C'+dbo.SPV_CONVERTINTTOVARCHAR(LEN(@v_saisieMessage), 3)+'D'+@v_saisieMessage
    exec @v_codeRetour = SPV_OSYSAJOUTECOMMANDE @vp_idTerm,  @v_cmd
  end

return @v_codeRetour



